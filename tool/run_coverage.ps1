$ErrorActionPreference = "Stop"

# Run test coverage and generate filtered report
Write-Host "Running flutter test with coverage..."
flutter test --coverage
if ($LASTEXITCODE -ne 0) {
    Write-Error "Flutter tests failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Host "Transforming coverage report (filtering main.dart and *.g.dart)..."
dart pub global run coverde transform --transformations "preset=skip_generated_and_main" -i coverage/lcov.info -o coverage/filtered.lcov.info -m w

Write-Host "Generating HTML coverage report..."
dart pub global run coverde report -i coverage/filtered.lcov.info -o coverage/html

Write-Host "Coverage value:"
dart pub global run coverde value -i coverage/filtered.lcov.info
