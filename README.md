# Link Scraper & Bookmarker

Extracts and filters HTML links from `.json` files, retrieves page titles, logs dead links, and exports results as:

* CSV
* Browser-compatible bookmark HTML
* Dead links list

Supports grouping by source file and flexible command-line flags.

## Features

* Greps for `https?://...html` links in `.json` files
* Follows redirects (301/302) to resolve final URLs
* Extracts page `<title>` text
* Outputs results to CSV
* Generates bookmark files importable into Chrome, Firefox, and others
* Groups bookmarks by source file (optional)
* Logs unreachable (dead) links to a separate file

## Usage

### 1. Extract Links from JSON

Create an input file called `html_links.txt`:

```bash
grep -rhoP 'https?://[^"]+\.html' ./your_json_dir --include="*.json" | \
  awk -v f=FILENAME '{ print f ":" $0 }' > html_links.txt
```

Each line should look like:
`./archives/1/example.json:https://example.com/page.html`

### 2. Run the Script

```bash
bash link_scraper.sh
```

### 3. Optional Flags

| Flag         | Description                                        |
| ------------ | -------------------------------------------------- |
| --csv        | Output `titles_by_source.csv`                      |
| --bookmarks  | Output `bookmarks.html` in standard browser format |
| --group      | Group by source file in bookmarks & CSV            |
| --dead-links | Log dead/unreachable links to `dead_links.txt`     |
| --all        | Run everything (default if no flags passed)        |

## Example Commands

Only generate a CSV file:
`bash link_scraper.sh --csv`

Only create bookmarks:
`bash link_scraper.sh --bookmarks`

Group bookmarks by source file:
`bash link_scraper.sh --bookmarks --group`

Run full suite (default behavior):
`bash link_scraper.sh`
or explicitly:
`bash link_scraper.sh --all`

## Output Files

* `titles_by_source.csv` – Clean CSV with source, title, and URL
* `bookmarks.html` – Standard HTML file that can be imported as bookmarks
* `dead_links.txt` – Any dead links (e.g., 404 or timeout)

## Requirements

* bash
* curl
* grep
* awk
* sed

These are standard on most Linux/macOS systems. On Windows, use Git Bash or WSL.

## Importing Bookmarks

To import `bookmarks.html`:

* Chrome: Bookmarks > Import Bookmarks and Settings > Choose HTML file
* Firefox: Bookmarks > Manage Bookmarks > Import & Backup > Import Bookmarks from HTML

## License

GPL

## Contributions Welcome

Fork the repo, open issues, or submit a PR — happy scraping!
