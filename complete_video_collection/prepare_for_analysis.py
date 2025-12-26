#!/usr/bin/env python3
"""
Convert synchronized video data into learning-tools batch format
for Claude Code analysis.
"""

import json
from pathlib import Path

def create_batches():
    """Create batches.json in learning-tools format"""

    sync_dir = Path('../synchronized')
    frames_base = Path('../frames')

    batches = {
        "project_name": "Complete Video Tutorial Collection",
        "total_videos": 0,
        "total_frames": 0,
        "batches": []
    }

    batch_id = 1

    for video_dir in sorted(sync_dir.iterdir()):
        if not video_dir.is_dir():
            continue

        timeline_file = video_dir / 'timeline.json'
        if not timeline_file.exists():
            continue

        with open(timeline_file) as f:
            data = json.load(f)

        video_id = video_dir.name
        total_frames = data['video_info']['total_frames']

        # Find corresponding frames directory
        frames_dir = frames_base / f"{video_id}_keyframes"
        if not frames_dir.exists():
            continue

        batches["total_videos"] += 1
        batches["total_frames"] += total_frames

        # Create batches (8 frames each, following learning-tools standard)
        timeline = data.get('timeline', [])

        for i in range(0, len(timeline), 8):
            batch_frames = timeline[i:i+8]

            # Get frame paths
            frame_paths = []
            for item in batch_frames:
                frame_path = Path(item['frame_path'])
                # Make path relative to project root
                rel_path = f"../frames/{frames_dir.name}/{frame_path.name}"
                frame_paths.append(rel_path)

            # Extract transcript snippets for context
            transcript_preview = " | ".join([
                item['transcript'][:50] + "..." if len(item['transcript']) > 50 else item['transcript']
                for item in batch_frames if item.get('transcript')
            ])[:200]

            batches["batches"].append({
                "batch_id": batch_id,
                "video_id": video_id,
                "video_title": video_id.split('-', 1)[1].replace('_', ' '),
                "frames": frame_paths,
                "frame_numbers": [item['frame_number'] for item in batch_frames],
                "timestamps": [item['timestamp_formatted'] for item in batch_frames],
                "transcript_preview": transcript_preview,
                "frame_count": len(frame_paths)
            })

            batch_id += 1

    # Save batches.json
    with open('batches.json', 'w') as f:
        json.dump(batches, f, indent=2)

    print(f"✓ Created batches.json")
    print(f"  - Videos: {batches['total_videos']}")
    print(f"  - Total frames: {batches['total_frames']}")
    print(f"  - Batches: {len(batches['batches'])}")
    print(f"  - Avg batch size: {batches['total_frames'] / len(batches['batches']):.1f} frames")

if __name__ == "__main__":
    create_batches()
