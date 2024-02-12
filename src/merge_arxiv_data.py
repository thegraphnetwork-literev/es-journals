import json
import sys

def merge_json_files(existing_file_path: str, new_file_path: str) -> None:
    """
    Merge the data from a new JSON file into an existing JSON file, avoiding duplicates based on the 'doi' field.

    Args:
        existing_file_path (str): The path to the existing JSON file.
        new_file_path (str): The path to the new JSON file.

    Returns:
        None
    """
    existing_dois = set()
    with open(existing_file_path, 'r') as f:
        existing_data = json.load(f)
        for entry in existing_data:
            existing_dois.add(entry['doi'])

    with open(new_file_path, 'r') as f:
        new_data = json.load(f)
        merged_data = existing_data.copy()
        for entry in new_data:
            if entry['doi'] not in existing_dois:
                merged_data.append(entry)

    with open(existing_file_path, 'w') as f:
        json.dump(merged_data, f, indent=4)

if __name__ == '__main__':
    # Get the file paths from the command line arguments
    existing_file_path = sys.argv[1]
    new_file_path = sys.argv[2]

    # Call the merge function
    merge_json_files(existing_file_path, new_file_path)
