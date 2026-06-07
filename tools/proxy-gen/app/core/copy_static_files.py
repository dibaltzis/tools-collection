import os
import shutil

def copy_static_files(src_dir: str, dst_dir: str):
    if not os.path.exists(src_dir):
        return

    for root, dirs, files in os.walk(src_dir):
        rel_path = os.path.relpath(root, src_dir)
        target_root = os.path.join(dst_dir, rel_path)

        os.makedirs(target_root, exist_ok=True)

        for file in files:
            src_file = os.path.join(root, file)
            dst_file = os.path.join(target_root, file)

            shutil.copy2(src_file, dst_file)
    
    print(f"[OK] Static files copied from {src_dir} to {dst_dir}")