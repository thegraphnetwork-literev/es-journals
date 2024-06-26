# es-journals

A service for rXiv REST API, such as biorxiv and medrxiv

* Free software: BSD 3 Clause
* Documentation: https://osl-incubator.github.io/es-journals

## Features

# SRC App

This application is designed to fetch the latest papers from the BioRxiv and MedRxiv servers. It automates the process of downloading the latest papers, merging them with existing data, and ensuring that the data is up to date.

## Installation

...

## Usage

Run the following command to fetch the latest papers from the desired index database server:
   ```
   ./src/fetch_rxivx_data.sh <index_name>
   ```
   Replace `<index_name>` with either "biorxiv" or "medrxiv" based on the database server you want to fetch the papers from.

---

## Credits

This package was created with
[scicookie](https://github.com/osl-incubator/scicookie) project template.
