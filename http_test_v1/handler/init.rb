require 'base64'
require 'net/http'

class HttpTestV1
  def initialize(input)
    # Parse the node XML document
    @input_document = REXML::Document.new(input)

    # Retrieve all of the handler info values and store them in a hash variable
    # named @info_values.
    @info_values = {}
    REXML::XPath.each(@input_document, "/handler/infos/info") do |item|
      @info_values[item.attributes["name"]] = item.text.to_s.strip
    end

    # Retrieve all of the handler parameters and store them in a hash variable
    # named @parameters.
    @parameters = {}
    REXML::XPath.each(@input_document, "/handler/parameters/parameter") do |item|
      @parameters[item.attributes["name"]] = item.text.to_s.strip
    end
  end

  def execute
    # Setup the HTTP connection (assuming ssl)
    http = Net::HTTP.new(@info_values['host'], @info_values['port'])
    http.use_ssl = true
    
    # Concatenate the username and password as required by basic auth
    credentials = "#{@info_values['username']}:#{@info_values['password']}"

    # Send the HTTP request
    response = http.send_request(
      @parameters['method'], 
      @parameters['path'], 
      @parameters['body'],
      { # "Content-Type" => "application/json",
        "Authorization" => "Basic #{Base64.strict_encode64(credentials)}" }
    )
    
    # Return (and escape) the results that were defined in the node.xml
    <<-RESULTS
    <results>
      <result name="Status Code">#{escape(response.code)}</result>
      <result name="Body">#{escape(response.body)}</result>
    </results>
    RESULTS
  end

  ##############################################################################
  # General handler utility functions
  ##############################################################################

  # This is a template method that is used to escape results values (returned in
  # execute) that would cause the XML to be invalid.  This method is not
  # necessary if values do not contain character that have special meaning in
  # XML (&, ", <, and >), however it is a good practice to use it for all return
  # variable results in case the value could include one of those characters in
  # the future.  This method can be copied and reused between handlers.
  def escape(string)
    # Globally replace characters based on the ESCAPE_CHARACTERS constant
    string.to_s.gsub(/[&"><]/) { |special| ESCAPE_CHARACTERS[special] } if string
  end
  # This is a ruby constant that is used by the escape method
  ESCAPE_CHARACTERS = {'&'=>'&amp;', '>'=>'&gt;', '<'=>'&lt;', '"' => '&quot;'}
end
