#!/usr/bin/env ruby

require 'bundler/setup'
require 'httparty'
require 'yaml'

class HassClient
  include HTTParty
  def initialize(host, token)
    @host = host
    @token = token
  end

  def call_service(domain:, name:, params:)
    path = "/api/services/#{domain}/#{name}"

    self.class.post(
      path,
      body: params.to_json,
      base_uri: @host,
      headers: {
        'Accept-Encoding' => '',
        'Authorization' => "Bearer #{@token}",
        'Content-Type' => 'application/json'
      },
      verify: false
    )
  end

  def clear_userclodes(node:)
    user_code_param = 16
    min_length = 4
    max_length = 8

    puts "clearing user codes on node #{node}"

    call_service(
      domain: 'zwave',
      name: 'set_config_parameter',
      params: {
        node_id: node,
        parameter: user_code_param,
        value: max_length,
      }
    )

    call_service(
      domain: 'zwave',
      name: 'set_config_parameter',
      params: {
        node_id: node,
        parameter: user_code_param,
        value: min_length,
      }
    )
  end

  def set_usercode(node:, slot:, usercode:)
    puts "setting node #{node} slot #{slot} to code #{usercode}"
    call_service(
      domain: 'lock',
      name: 'set_usercode',
      params: {
        node_id: node.to_s,
        code_slot: slot.to_s,
        usercode: usercode
      }
    )
  end
end

class LockManager
  def initialize
    @config = YAML.load_file('./config.yaml')
    @client = HassClient.new(@config['api_host'], @config['api_token'])
  end

  def run
    @config['nodes'].each do |node|
      @client.clear_userclodes(node: node)
      @config['codes'].each_with_index do |code, slot|
        puts @client.set_usercode(node: node, slot: slot + 1, usercode: code)
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  LockManager.new.run
end
