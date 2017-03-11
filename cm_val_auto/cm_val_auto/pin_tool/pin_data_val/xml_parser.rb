##########################################################################################
# Copyright (c) 2016, Freescale Semiconductor, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# o Redistributions of source code must retain the above copyright notice, this list
#   of conditions and the following disclaimer.
#
# o Redistributions in binary form must reproduce the above copyright notice, this
#   list of conditions and the following disclaimer in the documentation and/or
#   other materials provided with the distribution.
#
# o Neither the name of Freescale Semiconductor, Inc. nor the names of its
#   contributors may be used to endorse or promote products derived from this
#   software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Brief:
# ++++++++++++++++
# The xml data from pin tool, which is the target test data. This is a parser script to
# package the xml data to our pin model data.
#
# --- Code author: Bill.Yuan <Bill.Yuan@nxp.com>
# --- Version added: 0.0.1
#
# ++++++++++++++++
# --- 0.0.1: Bill.Yuan --- add structure framework, define the interface
#
##########################################################################################
require './pin_model'
require 'nokogiri'

class XMLParser < DataParser

  def initialize(xml_data_file)
    @doc = File.open(xml_data_file) {|file| Nokogiri::XML(file)}
  end

  def get_partnum()
    @doc.at_xpath("//part_number[@id]")["id"]
  end

  def get_pins_num()
    @doc.at_xpath("//part_number[@pins]")["pins"]
  end

  def get_package()
    @doc.at_xpath("//part_number/package").text
  end

  def parse(chip)
    puts "Parsing the xml data ......"

    begin
      parse_pins(chip)
      parse_peripheral_type(chip)
    rescue => ex
      puts ex.message
      puts ex.backtrace
      return false
    end

    return true
  end

  private
  def parse_pins(chip)
    pins_xml = @doc.xpath("//pins/pin")
    pins_xml.each do | pin_xml |
      pin = Pin.new()
      pin.coords = pin_xml["coords"]
      pin.port_name = get_portname(pin_xml)
      pin.combined_name = pin_xml["name"]

      chip.set_pin(pin.coords, pin)

      puts "\n----#{pin.coords},#{pin.combined_name}----" if Chip::DEBUG

      parse_connections(pin, pin_xml)
    end
  end

  def parse_connections(pin, pin_xml)
    #parse pin/connections
    connections_list_xml = pin_xml.xpath("./connections")
    connections_list_xml.each do | connections_xml |
      pin_signal = PinSignal.new()
      pin_signal.alt_name = connections_xml["package_function"]
      pin_signal.name = connections_xml["name_part"]
      pin_signal.peripheral_instance = get_peripheral_instance(connections_xml)
      pin_signal.features = get_peripheral_features(connections_xml)

      if pin_signal.name != nil
        puts pin_signal.alt_name + "-" + pin_signal.name if Chip::DEBUG
        index = pin_signal.alt_name.scan(/\d+/)[0].to_i

        pin.set_signal(pin_signal.alt_name, pin_signal)

        parse_disallow(pin_signal, connections_xml)
      end
    end
  end

  def parse_disallow(pin_signal, connections_xml)
    #parse pin/connections/connection/configuration/disallow
    disallow_list_xml = connections_xml.xpath("./connection/configuration/disallow")
    disallow_list_xml.each do | disallow_xml |
      port = Port.new()
      register = disallow_xml["register"]
      port.register = covert_port_name(register) if register != nil

      pin_signal.set_disallow(port.register, port) if port.register != nil
    end
  end

  def parse_peripheral_type(chip)
    peripheral_types_xml = @doc.xpath("//peripheral_types/peripheral_type")
    peripheral_types_xml.each do | type_xml |
      type = PeripheralType.new()
      type.name = type_xml["name"]
      descriptions = Array.new()
      descriptions.push(type_xml["description"])
      type.descriptions = descriptions

      chip.set_peripheral_type(type.name, type)
    end
  end

  def get_portname(pin_node)
    port_name_node = pin_node.at_xpath("./connections[@package_function='alt0']//assign[@register]")
    return nil if nil == port_name_node

    return covert_port_name(port_name_node["register"])
  end

  def covert_port_name(port_name)
    found_port_name = /PORT\w_PCR\d+/.match(port_name)
    if found_port_name
      num = found_port_name.to_s.scan(/\d+/)
      return "PT" + found_port_name.to_s[4] + num[0]
    end
    return nil
  end

  def get_peripheral_instance(signal_node)
    get_peripheral_attr(signal_node, "peripheral")
  end

  def get_peripheral_features(signal_node)
    get_peripheral_attr(signal_node, "features")
  end

  def get_peripheral_attr(signal_node, attr_name)
    perf_ref_node = signal_node.at_xpath("./connection/peripheral_signal_ref[@#{attr_name}]")
    return perf_ref_node["#{attr_name}"] if perf_ref_node != nil
  end
end