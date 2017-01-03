# Experian Precise Id Ruby Gem

[![Gem Version](https://badge.fury.io/rb/experian.png)][gem]
[![Build Status](https://secure.travis-ci.org/ehutzelman/experian.png?branch=master)][travis]
[![Code Climate](https://codeclimate.com/github/ehutzelman/experian.png)](https://codeclimate.com/github/ehutzelman/experian)

[gem]: https://rubygems.org/gems/experian
[travis]: http://travis-ci.org/ehutzelman/experian

Experian exposes nearly 30 different services.
This gem currently only implements the Precise Id product (identity validation).

*Net Connect is a business-to-business application gateway designed to allow access to Experian legacy systems via the public
Internet or Experian’s private TCP/IP extranet transport. It is a secure 168-bit encrypted transaction, using HTTPS.
Net Connect is a non-browser-based system requiring Experian certified client or vendor software at the user's location.
It utilizes XML for the input inquiry and has the capability of returning field-level XML, as well as our standard Automated
Response Format (ARF) (computer readable), Teletype Response Format (TTY) (human readable) and Parallel Profile
(both ARF and TTY in one response). Net Connect meets the encryption standards requirement in the Safeguards section of the
Gramm- Leach-Bliley (GLB) Act.*

#### Net Connect Products

* Address Update
* Authentication Services
* BizID
* Bullseye
* Checkpoint - File One Verification Solution
* Collection Advantage interactive
* Collection Report
* Connect Check
* Credit Profile
* Custom Solution
* Cross View
* CU Decision Expert
* Custom Strategist
* Decode
* Demographics
* Direct Check
* Employment Insight
* Fraud Shield
* Instant Prescreen
* New Consumer Identification
* Numeric Inquiry
* Parallel Profile
* Profile Summary
* Precise ID
* Precise ID Distributed
* Risk Models
* Social Search
* Truvue

## Installation

Add this line to your application's Gemfile:

    gem 'experian'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install experian

## Usage

### Configuration

Experian will provide you with the following authentication credentials when you sign up for their service:

```ruby
# Provide authentication credentials
Experian.configure do |config|
  config.preamble = "FCD2"
  config.op_initials = "AB"
  config.subcode = "1968543"
  config.user = "user"
  config.password = "password"
  config.vendor_number = "P55"
end

# Route requests to Experian test server instead of production
Experian.test_mode = true
```

### Using a product client

Products are namespaced under the Experian module. Example of how to create a client for the Connect Check product:

```ruby
client = ::Experian::PreciseId::Client.new
```

Once you have a client, you can make requests:

```ruby
response = client.check_id(first_name: "Homer", last_name: "Simpson")

response.success?
# => true
```

### Handling errors from Experian

```ruby
response = client.check_credit(first_name: "Homer", last_name: "Simpson", ssn: "NaN")

response.success?
# => false
response.error_message
# => "Invalid request format"
```

### Examine raw request and response XML
If you need to troubleshoot by viewing the raw XML, it is accesssible on the request and response objects of the client:

```ruby
# Inspect the request XML that was sent to Experian
request.xml
# => "<?xml version='1.0' encoding='utf-8'?>..."

# Inspect the response XML that was received from Experian
response.xml
# => "<?xml version='1.0' encoding='utf-8'?>..."
```

## Precise Id implementation

The XML returned from experian is incredibly detailed and complex. I've only implemented code for a very small portion of the data sent and returned.

### Primary Request

The Primary Request is the first request that is sent to the precise id server, it has the inital required data that must be submitted to experian to do an identity check. The response will be either acceptance, rejection or will require follow up questions. Follow up questions have not been implemented in this gem.

All paths in the below table are sub paths of this root path: `Experian/FraudSolutions/Request/Products/PreciseIDServer`

Some of the xml is set using the values specified below or using the data provided when this gem is initialized.

| xpath                 | value                 |
| PIDXMLVersion         | 06.00                 |
| Subscriber/Preamble   | set on initialization |
| Subscriber/OpInitials | set on initialization |
| Subscriber/SubCode    | set on initialization |
| Verbose               | "Y"                   |
| Vendor/VendorNumber   | set on initialization |
| Options/ProductOption | 21                    |

Other sections of the xml are set using a hash provided to the client when the request is run.

| xpath                                  | hash key                                                   |
| PrimaryApplicant/Name/Surname          | :last_name                                                 |
| PrimaryApplicant/Name/First            | :first_name                                                |
| PrimaryApplicant/CurrentAddress/Street | :street                                                    |
| PrimaryApplicant/CurrentAddress/City   | :city                                                      |
| PrimaryApplicant/CurrentAddress/State  | :state                                                     |
| PrimaryApplicant/CurrentAddress/Zip    | :zip                                                       |
| PrimaryApplicant/Phone/Number          | :phone                                                     |
| PrimaryApplicant/DOB                   | :dob                                                       |
| PrimaryApplicant/EmailAddress          | :email                                                     |
| Options/ReferenceNumber                | "XML PROD OP 19" unless overridden using :reference_number |
| IPAddress                              | :ip_address                                                |

### Base Response for all responses

| method        |                                                                                                                                     |
| success?      | returns false if root node of the returned xml is "NetConnectResponse", if the result was successful it would start with "Experian" |
| error?        | the opposite to `success?`                                                                                                          |
| error_code    | the content of NetConnectResponse/CompletionCode                                                                                    |
| reference_id  | the content of NetConnectResponse/ReferenceId                                                                                       |
| error_message | the content of NetConnectResponse/ErrorMessage                                                                                      |

### Precise ID Response

Note: The precise id section is under the path Experian/FraudSolutions/Response/Products/PreciseIDServer

| method            |                                                                                                                                 |
| success?          | returns true if the PreciseIDServer section exists and the error section ( PreciseIdServer/Error ) doesn't exist                |
| error?            | opposite to `success?`                                                                                                          |
| error_code        | returns the content of PreciseIdServer/Error/ErrorCode                                                                          |
| error_message     | returns the content of PreciseIdServer/Error/ErrorDesciption                                                                    |
| session_id        | returns the content of PreciseIdServer/SessionID                                                                                |
| initial_decision  | returns the content of PreciseIdServer/Summary/InitialDecision                                                                  |
| final_decision    | returns the content of PreciseIdServer/Summary/FinalDecision                                                                    |
| accept_refer_code | returns the content of PreciseIdServer/KBAScore/ScoreSummary/AcceptReferCode                                                    |
| accept_refer_code | returns the content of PreciseIdServer/KBA/QuestionSet/AcceptReferCode{QuestionType,QuestionText,QuestionSelect/QuestionChoice} |

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Copyright

Copyright (c) 2012-2013 Eric Hutzelman.
See [LICENSE][] for details.

[license]: LICENSE.txt
