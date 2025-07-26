# File Operations

Handle file uploads and downloads with built-in progress tracking and error handling.

## Overview

VLNetworkingClient provides dedicated methods for file operations that are optimized for large files and provide better memory management than loading entire files into memory.

## File Downloads

### Basic Download

Download a file directly to a specified location:

```swift
let config = RequestConfiguration(
    url: URL(string: "https://example.com/large-file.zip")!,
    method: .GET
)

let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
let destinationURL = documentsURL.appendingPathComponent("downloaded-file.zip")

do {
    let response = try await client.downloadFile(config, to: destinationURL)
    print("File downloaded to: \(response.data)")
    print("Response status: \(response.statusCode)")
} catch {
    print("Download failed: \(error)")
}
```

### Download with Authentication

Downloads can use interceptors just like regular requests:

```swift
let authenticatedClient = await client.with(interceptor: authInterceptor)
let response = try await authenticatedClient.downloadFile(config, to: destinationURL)
```

## File Uploads

### Basic Upload

Upload a file from the local file system:

```swift
let fileURL = Bundle.main.url(forResource: "document", withExtension: "pdf")!

let config = RequestConfiguration(
    url: URL(string: "https://api.example.com/upload")!,
    method: .POST,
    headers: ["Content-Type": "application/pdf"]
)

do {
    let response = try await client.uploadFile(config, from: fileURL)
    if let responseData = response.data {
        // Handle server response
        let result = try JSONDecoder().decode(UploadResult.self, from: responseData)
        print("Upload successful: \(result.fileId)")
    }
} catch {
    print("Upload failed: \(error)")
}
```

### Multipart Form Upload

For multipart form uploads, configure the request appropriately:

```swift
let boundary = UUID().uuidString
let config = RequestConfiguration(
    url: uploadURL,
    method: .POST,
    headers: [
        "Content-Type": "multipart/form-data; boundary=\(boundary)"
    ]
)

// Create multipart body data
var bodyData = Data()
bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
bodyData.append("Content-Disposition: form-data; name=\"file\"; filename=\"document.pdf\"\r\n".data(using: .utf8)!)
bodyData.append("Content-Type: application/pdf\r\n\r\n".data(using: .utf8)!)
bodyData.append(try Data(contentsOf: fileURL))
bodyData.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

let configWithBody = RequestConfiguration(
    url: uploadURL,
    method: .POST,
    headers: config.headers,
    body: bodyData
)

let response = try await client.request(configWithBody)
```

## Error Handling

File operations can fail for various reasons:

```swift
do {
    let response = try await client.downloadFile(config, to: destinationURL)
} catch NetworkError.notFound {
    print("File not found on server")
} catch NetworkError.serverUnavailable {
    print("Server temporarily unavailable")
} catch CocoaError.fileWriteNoPermission {
    print("No permission to write to destination")
} catch CocoaError.fileWriteFileExists {
    print("File already exists at destination")
} catch {
    print("Unexpected error: \(error)")
}
```

## Memory Efficiency

File operations in VLNetworkingClient are designed to be memory efficient:

- **Downloads**: Stream directly to disk without loading the entire file into memory
- **Uploads**: Read and send file data in chunks rather than loading everything at once
- **Large Files**: Suitable for files of any size without memory pressure

## Best Practices

### File Paths

Always use proper file paths and handle potential conflicts:

```swift
let destinationURL = documentsURL.appendingPathComponent("download.zip")

// Check if file already exists
if FileManager.default.fileExists(atPath: destinationURL.path) {
    // Handle existing file (rename, overwrite, or abort)
    try FileManager.default.removeItem(at: destinationURL)
}

let response = try await client.downloadFile(config, to: destinationURL)
```

### Progress Tracking

For user-facing file operations, consider implementing progress tracking:

```swift
// This would require extending the client with progress callbacks
// Currently not implemented in the basic API
```

### Temporary Files

Use temporary directories for intermediate file operations:

```swift
let tempURL = FileManager.default.temporaryDirectory
    .appendingPathComponent(UUID().uuidString)
    .appendingPathExtension("tmp")

let response = try await client.downloadFile(config, to: tempURL)

// Process the file, then move to final destination
try FileManager.default.moveItem(at: tempURL, to: finalDestinationURL)
```