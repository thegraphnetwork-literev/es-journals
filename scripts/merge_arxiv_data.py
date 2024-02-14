import json
import sys

def merge_json_files(full_data_path: str, downloaded_data_path: str) -> None:
    """
    Merge the data from a new JSON file into an existing JSON file, avoiding duplicates based on the 'title' and 'version' fields.

    Args:
        full_data_path (str): The path to the existing JSON file.
        downloaded_data_path (str): The path to the new JSON file.

    Returns:
        None
    """
    # Use a set to track unique combinations of title and version
    existing_titles_versions = set()
    try:
        with open(full_data_path, 'r', encoding='utf-8') as f:
            existing_data = json.load(f)
            for entry in existing_data:
                # Create a unique key using title and version
                unique_key = f"{entry['title']}_{entry['version']}"
                existing_titles_versions.add(unique_key)
    except FileNotFoundError:
        # If the file doesn't exist, start with an empty list
        existing_data = []

    with open(downloaded_data_path, 'r', encoding='utf-8') as f:
        new_data = json.load(f)
        for entry in new_data:
            # Check the unique combination of title and version
            unique_key = f"{entry['title']}_{entry['version']}"
            if unique_key not in existing_titles_versions:
                existing_data.append(entry)

    with open(full_data_path, 'w', encoding='utf-8') as f:
        json.dump(existing_data, f, indent=4)

if __name__ == '__main__':
    # Get the file paths from the command line arguments
    if len(sys.argv) > 2:
        full_data_path = sys.argv[1]
        downloaded_data_path = sys.argv[2]

        # Call the merge function
        merge_json_files(full_data_path, downloaded_data_path)
    else:
        print("Please provide both the full data path and the downloaded data path as arguments.")
