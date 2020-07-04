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

  def set_usercode(node:, slot:, usercode:)
    puts "setting node #{node} slot #{slot} to code #{usercode}"
    self.class.post(
      '/api/services/lock/set_usercode', 
      body: {
        node_id: node.to_s,
        code_slot: slot.to_s,
        usercode: usercode
      }.to_json,
      base_uri: @host,
      headers: {
        'Accept-Encoding' => '', 
        'Authorization' => "Bearer #{@token}", 
        'Content-Type' => 'application/json' 
      },
      verify: false
    )
  end
end

class LockManager
  def initialize
    @config = YAML.load_file('./config.yaml')
    @client = HassClient.new(@config['api_host'], @config['api_token'])
  end

  def run
    @config['codes'].each_with_index do |code, slot|
      @config['nodes'].each do |node|
        puts @client.set_usercode(node: node, slot: slot, usercode: code)
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  LockManager.new.run
end
