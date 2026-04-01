## 1.0.19

- Improve `Content-Type` handling between `FormData` and non-`FormData` requests to avoid cross-request header conflicts
- Preserve custom non-JSON `Content-Type` on retry (for example `text/plain` or `application/x-www-form-urlencoded`)
- Prevent refresh deadlock risk when refresh flow uses the same `Dio` instance
- Harden refresh completer error handling to avoid unhandled async errors
- Make debug logging safer when response data is not JSON-encodable

## 1.0.18

- Prevent infinite refresh-token loop by allowing only one refresh/retry cycle per request chain
- Add retry marker guard so requests that still return 401 after retry are not refreshed repeatedly

## 1.0.17

- Fix reset header if for non FormData type request

## 1.0.16

- Fix retryRequest if request type FormData

## 1.0.15

- Sparate headers and headersAsync based on needed

## 1.0.14

- Add idle callback on ApiResult

## 1.0.13

- Set headers as async function to support preparing headers using async process

## 1.0.12

- Adjust completer to prevent multiple refresh token request

## 1.0.11

- Adjust logging form data (multiparts) data delivery

## 1.0.10

- Fix shake for chucker integration 

## 1.0.9

- Separate content type FormData and others

## 1.0.8

- Upgrade chucker 1.9.0 (No need override)

## 1.0.7

- Format with dart format

## 1.0.6

- Add custom timout duration
- Add custom global error and global error network message

## 1.0.5

- Add supported platform
- Update Readme.md
- Optimize code

## 1.0.4

- Fix overriding refresh token function

## 1.0.3

- Update Documentation & Example Implementation

## 1.0.2

- Update table of content on README

## 1.0.1

- Complete documentation
- Optimizing functions

## 1.0.0

- Initial version.
