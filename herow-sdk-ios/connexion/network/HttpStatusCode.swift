//
//  HttpStatusCode.swift
//  ConnectPlaceCommon
//
//  Created by Ludovic Vimont on 14/04/2020.
//  Copyright © 2020 Connecthings. All rights reserved.
//

import Foundation

// swiftlint:disable identifier_name
public class HttpStatusCode {
    /**
     * HTTP Status-Code 200: OK.
     */
    public static let HTTP_OK = 200

    /**
     * HTTP Status-Code 201: Created.
     */
    public static let HTTP_CREATED = 201

    /**
     * HTTP Status-Code 202: Accepted.
     */
    public static let HTTP_ACCEPTED = 202

    /**
     * HTTP Status-Code 203: Non-Authoritative Information.
     */
    public static let HTTP_NOT_AUTHORITATIVE = 203

    /**
     * HTTP Status-Code 204: No Content.
     */
    public static let HTTP_NO_CONTENT = 204

    /**
     * HTTP Status-Code 205: Reset Content.
     */
    public static let HTTP_RESET = 205

    /**
     * HTTP Status-Code 206: Partial Content.
     */
    public static let HTTP_PARTIAL = 206

    /* 3XX: relocation/redirect */

    /**
     * HTTP Status-Code 300: Multiple Choices.
     */
    public static let HTTP_MULT_CHOICE = 300

    /**
     * HTTP Status-Code 301: Moved Permanently.
     */
    public static let HTTP_MOVED_PERM = 301

    /**
     * HTTP Status-Code 302: Temporary Redirect.
     */
    public static let HTTP_MOVED_TEMP = 302

    /**
     * HTTP Status-Code 303: See Other.
     */
    public static let HTTP_SEE_OTHER = 303

    /**
     * HTTP Status-Code 304: Not Modified.
     */
    public static let HTTP_NOT_MODIFIED = 304

    /**
     * HTTP Status-Code 305: Use Proxy.
     */
    public static let HTTP_USE_PROXY = 305

    /* 4XX: client error */

    /**
     * HTTP Status-Code 400: Bad Request.
     */
    public static let HTTP_BAD_REQUEST = 400

    /**
     * HTTP Status-Code 401: Unauthorized.
     */
    public static let HTTP_UNAUTHORIZED = 401

    /**
     * HTTP Status-Code 402: Payment Required.
     */
    public static let HTTP_PAYMENT_REQUIRED = 402

    /**
     * HTTP Status-Code 403: Forbidden.
     */
    public static let HTTP_FORBIDDEN = 403

    /**
     * HTTP Status-Code 404: Not Found.
     */
    public static let HTTP_NOT_FOUND = 404

    /**
     * HTTP Status-Code 405: Method Not Allowed.
     */
    public static let HTTP_BAD_METHOD = 405

    /**
     * HTTP Status-Code 406: Not Acceptable.
     */
    public static let HTTP_NOT_ACCEPTABLE = 406

    /**
     * HTTP Status-Code 407: Proxy Authentication Required.
     */
    public static let HTTP_PROXY_AUTH = 407

    /**
     * HTTP Status-Code 408: Request Time-Out.
     */
    public static let HTTP_CLIENT_TIMEOUT = 408

    /**
     * HTTP Status-Code 409: Conflict.
     */
    public static let HTTP_CONFLICT = 409

    /**
     * HTTP Status-Code 410: Gone.
     */
    public static let HTTP_GONE = 410

    /**
     * HTTP Status-Code 411: Length Required.
     */
    public static let HTTP_LENGTH_REQUIRED = 411

    /**
     * HTTP Status-Code 412: Precondition Failed.
     */
    public static let HTTP_PRECON_FAILED = 412

    /**
     * HTTP Status-Code 413: Request Entity Too Large.
     */
    public static let HTTP_ENTITY_TOO_LARGE = 413

    /**
     * HTTP Status-Code 414: Request-URI Too Large.
     */
    public static let HTTP_REQ_TOO_LONG = 414

    /**
     * HTTP Status-Code 415: Unsupported Media Type.
     */
    public static let HTTP_UNSUPPORTED_TYPE = 415

    /**
     * HTTP Status-Code 429: Too Many Requests.
     */
    public static let HTTP_TOO_MANY_REQUESTS = 429

    /* 5XX: server error */

    /**
     * HTTP Status-Code 500: Internal Server Error.
     */
    public static let HTTP_INTERNAL_ERROR = 500

    /**
     * HTTP Status-Code 501: Not Implemented.
     */
    public static let HTTP_NOT_IMPLEMENTED = 501

    /**
     * HTTP Status-Code 502: Bad Gateway.
     */
    public static let HTTP_BAD_GATEWAY = 502

    /**
     * HTTP Status-Code 503: Service Unavailable.
     */
    public static let HTTP_UNAVAILABLE = 503

    /**
     * HTTP Status-Code 504: Gateway Timeout.
     */
    public static let HTTP_GATEWAY_TIMEOUT = 504

    /**
     * HTTP Status-Code 505: HTTP Version Not Supported.
     */
    public static let HTTP_VERSION = 505
}
