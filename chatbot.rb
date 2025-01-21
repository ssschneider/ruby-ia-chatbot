require "capybara"
require "capybara/dsl"
require "webdrivers/chromedriver"
require "selenium-webdriver"
require "net/https"
require "json"
require "pry"
require "uri"

class Chatbot
  include Capybara::DSL

  GEMINI_API_KEY="[YOUR GEMINI API KEY]"
  API_URL="https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=#{GEMINI_API_KEY}"

  def initialize
    Selenium::WebDriver::Chrome.path = "/usr/bin/google-chrome"
    
    Capybara.register_driver :selenium do |app|
      Capybara::Selenium::Driver.new(app, browser: :chrome)
    end

    Capybara.default_driver = :selenium
    Capybara.default_max_wait_time = 10

    visit("https://web.whatsapp.com/")
    sleep(20)
    find("span", text: "Você").click ## The contact to send the messages
    read_and_answer_messages
  end

  private
  def read_and_answer_messages
    loop do
      messages = []

      chat_messages = all("span.selectable-text")
      chat_messages.each { |element| messages << element.text }

      context = "Esse contato está me mandando mensagens. Baseado nas últimas mensagens, converse com ela identificando as necessidades e solucionando seus problemas.
      
      Se identifique como assistente pessoal da Sarah e caso não tenha uma resposta específica informe que eu retornarei o contato depois.

      As últimas mensagens do contato são: #{messages}"
      
      uri = URI(API_URL)

      headers = {
        'Content-Type': 'application/json'
      }

      body = {
        "contents": [{
          "parts": [{ "text": context }]
        }]
      }.to_json

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.request_uri, headers)
      request.body = body

      response = http.request(request)
      json_response = JSON.parse(response.body)

      gemini_response = json_response["candidates"][0]["content"]["parts"][0]["text"]

      message_input = find("div[aria-placeholder='Digite uma mensagem']")
      message_input.send_keys(gemini_response)
      message_input.send_keys(:enter)

      sleep(30)
    end
  end
end

Chatbot.new