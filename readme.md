# Network Testing Script

This PowerShell script is designed to perform parallel network tests based on a CSV configuration file. It allows network administrators to check the availability of TCP ports, perform ping tests, and resolve DNS names against specified servers. The results are color-coded for quick identification of successes and failures.

## Features

- **TCP Port Testing**: Checks if a TCP port is open on a specified target with a custom timeout.
- **Ping Testing**: Verifies if a target is reachable via ping.
- **DNS Resolution Testing**: Tests if a DNS server can resolve a specified hostname and displays the resolved IP address.
- **Parallel Execution**: Tests are run in parallel to optimize performance and reduce execution time.
- **CSV Configuration**: Tests are configured through a CSV file, making it easy to adjust and extend the test cases.

## Usage

### Script Parameters

- `-CsvFilePath`: Path to the CSV file containing the test configuration.

### CSV File Format

The CSV file should have the following columns:

- `Name`: A descriptive name for the test.
- `Target`: The target IP address or DNS server.
- `TestType`: The type of test to perform (`TCP`, `Ping`, or `DNS`).
- `ExpectedResult`: Expected result of the test (`1` for success, `0` for failure).

Example CSV file:

```csv
Cloudflare,1.1.1.1,Ping,1
Cloudflare,1.1.1.1,DNS,1
Google,1.1.1.1,Ping,1
Google,1.1.1.1,DNS,1
Google Website,google.com,443,1
YouTube Website,youtube.com,443,1
```

## Running the Script

Run the script in PowerShell by providing the path to the CSV file:

```powershell
.\PortCheck.ps1 -CsvFilePath .\example.csv
```

## Output

The script provides color-coded output indicating the success or failure of each test:

- Green: Test successful
- Red: Test failed
- Yellow: Unknown test type

Example output:

```
.\PortCheck.ps1 -CsvFilePath example.csv

Test successful: Cloudflare (1.1.1.1) is reachable with ping
Test successful: google.com resolved by DNS server 1.1.1.1 with IP 2a00:1450:401b:808::200e 142.251.143.78
Test successful: Google (1.1.1.1) is reachable with ping
Test successful: google.com resolved by DNS server 1.1.1.1 with IP 2a00:1450:401b:808::200e 216.58.208.206
Test successful: Google Website (google.com) on Port 443 is reachable
Test successful: YouTube Website (youtube.com) on Port 443 is reachable
```

## Contributing

If you have suggestions or improvements, feel free to submit a pull request or open an issue.
