# Watches for changes in src files -> if changed then re-run specified script

import os
# import json
import time
import subprocess

def watcher () :
    target_files_config_path = 'build_tools/watcher_target_files.txt'
    target_build_script = ['bash', 'build.sh', '-bc']
    target_files = []
    target_files_modification_timestamps = []
    files_modified = False
 
    with open(target_files_config_path) as watcher_target_files :
        raw_target_files = watcher_target_files.read()

    target_files = raw_target_files.split('\n')[0:-1]
    target_files_modification_timestamps = [0] * len(target_files)

    while True:
        for x in range(len(target_files)) :
            file_modified_time = os.stat(target_files[x]).st_mtime

            if file_modified_time != target_files_modification_timestamps[x] :
                target_files_modification_timestamps[x] = file_modified_time
                files_modified = True

        if files_modified :
            files_modified = False

            subprocess.run(['clear'])
            result = subprocess.run(target_build_script, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            print(result.stdout.decode('utf-8'))
            print(result.stderr.decode('utf-8'))

            time.sleep(0.3)


if __name__ == "__main__" :
    watcher()
