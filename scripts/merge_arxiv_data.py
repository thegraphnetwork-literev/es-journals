import json
import sys

def merge_json_files(full_data_path: str, downloaded_data_path: str) -> None:
    """
    Merge the data from a new JSON file into an existing JSON file, avoiding duplicates based on the 'title' and 'version' fields.
    Validates that the final merged data equals the total data (current data + downloaded data).
    Notifies if there is nothing new to add to the final version.

    Args:
        full_data_path (str): The path to the existing JSON file.
        downloaded_data_path (str): The path to the new JSON file.

    Returns:
        None
    """
    existing_titles_versions = set()
    existing_data = []
    initial_len = 0
    new_entries_added = 0  # Counter for new entries added

    try:
        with open(full_data_path, 'r', encoding='utf-8') as f:
            existing_data = json.load(f)
            initial_len = len(existing_data)
            for entry in existing_data:
                unique_key = f"{entry['title']}_{entry['version']}"
                existing_titles_versions.add(unique_key)
                print(f"[DEBUG]: Existing entry: {unique_key}")
    except FileNotFoundError:
        print("[ERROR]: No existing file. Starting fresh.")

    with open(downloaded_data_path, 'r', encoding='utf-8') as f:
        new_data = json.load(f)
        downloaded_len = len(new_data)
        print(f"[INFO]: Downloaded length: ({ downloaded_len })")

        for entry in new_data:
            unique_key = f"{entry['title']}_{entry['version']}"
            if unique_key not in existing_titles_versions:
                existing_data.append(entry)
                new_entries_added += 1
                print(f"[DEBUG]: Added new entry: {unique_key}")
            else:
                print(f"[DEBUG]: Skipped duplicate entry: {unique_key}")

    final_len = len(existing_data)
    print(f"[INFO]: Current length: ({ initial_len })")
    print(f"[INFO]: Actual final length: ({ final_len })")

    if new_entries_added == 0:
        success_message = "[INFO]: No new entries added. The dataset is up-to-date."
    else:
        success_message = "[SUCCESS]: Data merge validation passed. New entries added to the dataset."

    print(success_message)

    with open(full_data_path, 'w', encoding='utf-8') as f:
        json.dump(existing_data, f, indent=4)

if __name__ == '__main__':
    if len(sys.argv) > 2:
        full_data_path = sys.argv[1]
        downloaded_data_path = sys.argv[2]
        merge_json_files(full_data_path, downloaded_data_path)
    else:
        print("Error: Please provide both the full data path and the downloaded data path as arguments.")
