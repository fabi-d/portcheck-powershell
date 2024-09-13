# Script to parallel check TCP ports, Ping tests, and DNS resolution based on a CSV file containing the name, target, test type (TCP/Ping/DNS), and expected result

param (
  [string]$CsvFilePath
)

# Check if the CSV file exists
if (-not (Test-Path $CsvFilePath)) {
  Write-Host "CSV file not found: $CsvFilePath" -ForegroundColor Red
  exit 1
}

# Import the CSV file
$tests = Import-Csv -Path $CsvFilePath -Header Name, Target, TestType, ExpectedResult

# List for parallel jobs
$jobs = @()

# Start the tests in parallel
foreach ($test in $tests) {
  # skip first row if it contains headers
  if ($test.Name -eq 'Name' -and $test.Target -eq 'Target') {
    continue
  }

  $name = $test.Name
  $target = $test.Target
  $testType = $test.TestType
  $expectedResult = [int]$test.ExpectedResult

  # Create a job for each test
  $jobs += Start-Job -ScriptBlock {
    param ($name, $target, $testType, $expectedResult)

    # Function to test a TCP port with a 5-second timeout
    function Test-TcpPort {
      param (
        [string]$target,
        [string]$port, # Accept port as string and convert later
        [int]$expected
      )

      try {
        # Convert port to integer
        $intPort = [int]$port
                
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.ReceiveTimeout = 5000  # 5-second timeout for receive
        $tcpClient.SendTimeout = 5000  # 5-second timeout for send

        # Asynchronous connect with manual timeout
        $asyncResult = $tcpClient.BeginConnect($target, $intPort, $null, $null)
        $waitHandle = $asyncResult.AsyncWaitHandle

        if ($waitHandle.WaitOne(5000)) {
          # 5-second timeout for connection
          $tcpClient.EndConnect($asyncResult)
          if ($tcpClient.Connected) {
            $tcpClient.Close()
            if ($expected -eq 1) {
              Write-Host "Test successful: $name ($target) on Port $intPort is reachable" -ForegroundColor Green
            }
            else {
              Write-Host "Test failed: $name ($target) on Port $intPort should not be reachable" -ForegroundColor Red
            }
          }
        }
        else {
          $tcpClient.Close()
          throw "Connection timed out"
        }
      }
      catch {
        # Connection failed
        if ($expected -eq 0) {
          Write-Host "Test successful: $name ($target) on Port $intPort is not reachable (expected)" -ForegroundColor Green
        }
        else {
          Write-Host "Test failed: $name ($target) on Port $intPort is not reachable" -ForegroundColor Red
        }
      }
    }

    # Function to test Ping
    function Test-Ping {
      param (
        [string]$target,
        [int]$expected
      )

      $ping = Test-Connection -ComputerName $target -Count 1 -Quiet

      if ($ping -eq $true) {
        if ($expected -eq 1) {
          Write-Host "Test successful: $name ($target) is reachable with ping" -ForegroundColor Green
        }
        else {
          Write-Host "Test failed: $name ($target) should not be reachable with ping" -ForegroundColor Red
        }
      }
      else {
        if ($expected -eq 0) {
          Write-Host "Test successful: $name ($target) is not reachable with ping (expected)" -ForegroundColor Green
        }
        else {
          Write-Host "Test failed: $name ($target) is not reachable with ping" -ForegroundColor Red
        }
      }
    }

    # Function to test DNS resolution
    function Test-DNS {
      param (
        [string]$dnsServer,
        [string]$hostname,
        [int]$expected
      )

      try {
        $dnsResult = Resolve-DnsName -Name $hostname -Server $dnsServer -ErrorAction Stop
        if ($dnsResult) {
          if ($expected -eq 1) {
            Write-Host "Test successful: $hostname resolved by DNS server $dnsServer with IP $($dnsResult.IPAddress)" -ForegroundColor Green
          }
          else {
            Write-Host "Test failed: $hostname should not be resolved by DNS server $dnsServer, but got IP $($dnsResult.IPAddress)" -ForegroundColor Red
          }
        }
      }
      catch {
        if ($expected -eq 0) {
          Write-Host "Test successful: $hostname not resolved by DNS server $dnsServer (expected)" -ForegroundColor Green
        }
        else {
          Write-Host "Test failed: $hostname not resolved by DNS server $dnsServer" -ForegroundColor Red
        }
      }
    }

    # Execute the test logic
    if ($testType -match '^\d+$') {
      # TCP port test if testType is a number
      Test-TcpPort -target $target -port $testType -expected $expectedResult
    }
    elseif ($testType -eq 'Ping') {
      # Ping test
      Test-Ping -target $target -expected $expectedResult
    }
    elseif ($testType -eq 'DNS') {
      # DNS resolution test
      Test-DNS -dnsServer $target -hostname 'google.com' -expected $expectedResult
    }
    else {
      Write-Host "Unknown test type: $testType" -ForegroundColor Yellow
    }
  } -ArgumentList $name, $target, $testType, $expectedResult
}

# Wait for all jobs to finish
$jobs | ForEach-Object { 
  Receive-Job -Job $_ -Wait | Out-Null  # Suppress True/False output
  Remove-Job -Job $_
}

Write-Host "All tests completed." -ForegroundColor Cyan