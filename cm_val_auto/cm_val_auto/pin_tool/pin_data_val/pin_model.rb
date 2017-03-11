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
# This is the class definition file, define the basic structure how to store the chip,
# pins, signals and ports.
# It also includes the compare method and abstract parser class to easy to validation
# the data.
#
# --- Code author: Bill.Yuan <Bill.Yuan@nxp.com>
# --- Version added: 0.0.1
#
# ++++++++++++++++
# --- 0.0.1: Bill.Yuan --- add the all classes and their methods, set up the structure
#
##########################################################################################
$is_peripherial_val = false
$is_features_val = false

class ComparableData
  attr_accessor :type, :key, :key_description, :fail_num, :result_parent

  def initialize(type, key, key_description, atrrs_name_list, subhash_list)
    @type = type
    @key = key
    @key_description = key_description
    @attrs_name_list = atrrs_name_list
    @subhash_list = subhash_list
    @fail_num = 0
    @result_items = Hash.new()
    @result_parent = nil
  end

  def set_testresult_parent(result_parent)
    @result_parent = result_parent
  end

  def compare(target)
    if compare_pre(target)
      compare_attrs(target)
      compare_sublist(target)
    end

    save_result(target) if @result_parent != nil
    return @fail_num == 0
  end

  protected
  def compare_pre(target)
    if target == nil
       @fail_num = @fail_num + 1
       return false
    end
    return true
  end

  def compare_attrs(target)
    return if nil == @attrs_name_list

    @attrs_name_list.each do |attr_name|
      compare_attr(attr_name, target)
    end
  end

  def compare_attr(attr_name, target)
    return if nil == attr_name or attr_name.length() <= 0

    required = instance_variable_get("@" + attr_name)
    actual = target.instance_variable_get("@" + attr_name)
    if !smart_match(required, actual)
      @fail_num = @fail_num + 1
      set_result_attr_fail(attr_name, required, actual)
    end
  end

  def smart_match(required, actual)
    if required == actual
      #quick check
      return true
    else
      if nil == required or nil == actual
        return false
      end

      # for the multi signal combination, such as UART0_TX/PTE5, and PTE5/UART0_TX
      # we need strict the comparison, make sure all are the same after sorting, and
      # no redundant and missing
      required_list = required.split("/").sort!
      actual_list = actual.split("/").sort!

      return required_list == actual_list
    end
  end

  def set_result_attr_fail(attr_name, required, actual)
    @result_items[attr_name] = "FAIL --- Require: #{required}, actual: #{actual}"
  end

  def compare_sublist(target)
    return if nil == @subhash_list

    @subhash_list.each do | sublist_item |
      compare_sublist_item(sublist_item, target)
    end
  end

  def compare_sublist_item(sublist_item, target)
    required_hash = instance_variable_get("@" + sublist_item)
    actual_hash = target.instance_variable_get("@" + sublist_item)

    verify_mismatch(sublist_item, required_hash, actual_hash)
    verify_redundant(sublist_item, required_hash, actual_hash)
  end

  def verify_mismatch(sublist_item, required_hash, actual_hash)
    required_hash.each do |key, required|
      actual = actual_hash[key]
      @result_items[sublist_item] = Hash.new() if nil == @result_items[sublist_item]
      required.set_testresult_parent(@result_items[sublist_item])
      if !required.compare(actual)
        @fail_num = @fail_num + 1
      end
    end
  end

  def verify_redundant(sublist_item, required_hash, actual_hash)
    actual_hash.each do |key, actual|
      required = required_hash[key]
      if nil == required
        @fail_num = @fail_num + 1
        @result_items[sublist_item] = Hash.new() if nil == @result_items[sublist_item]
        @result_items[sublist_item][actual.key] = "Warning, redundant item -- #{actual.key_description.to_s}!"
      end
    end
  end

  def save_result(target)
    if @fail_num > 0
      if target != nil
        name = "#{@type},#{@key}---FAIL,#{@fail_num}_mismatch"
      else
        name = "#{@type},#{@key}---FAIL,missing_target_info-#{@key_description.to_s}"
      end

      if @result_items.size > 0
        @result_parent[name] = @result_items
      else
        @result_parent[name] = ""
      end
    end
  end
end


class Chip < ComparableData
  attr_accessor :info

  TYPE = "Chip"
  DEBUG = false

  class Info
    attr_accessor :part_num, :pins_num, :package

    def initialize(partnum_name, pins_num, package_name)
      @part_num = partnum_name
      @pins_num = pins_num
      @package = package_name
    end

    def get_info_key()
      @part_num + "(" + @pins_num + "," + @package + ")"
    end
  end

  def initialize(xml_config)
    @config = xml_config
    @pins = Hash.new()
    @peripheral_types = Hash.new()
    get_parser()
    get_info()
    super(TYPE, @info.get_info_key(), @package, ["info"], ["pins", "peripheral_types"])
  end

  def set_adv_options(is_peripherial_val, is_features_val)
    $is_peripherial_val = is_peripherial_val
    $is_features_val = is_features_val
  end

  def get_parser()
    @parser = XMLParser.new(@config) if nil == @parser
    return @parser
  end

  def get_info()
    if nil == @info
      @info = Chip::Info.new(@parser.get_partnum(), @parser.get_pins_num(), @parser.get_package())
    end
    return @info
  end

  def parse()
    @parser.parse(self)
  end

  def set_pin(key, pin)
    if nil == pin
      puts "Fail, pin is null!"
      return
    end

    if !pin.instance_of? Pin
      puts "Fail, pin is not a Pin instance!"
      return
    end

    pin.key = key
    pin.key_description = pin.port_name
    @pins[key] = pin
  end

  def clear_pins()
    @pins.clear()
  end

  def set_peripheral_type(key, type)
    if nil == type
      puts "Fail, peripheral type is null!"
      return
    end

    if !type.instance_of? PeripheralType
      puts "Fail, peripheral type is not a PeripheralType instance!"
      return
    end

    type.key = key
    type.key_description = type.descriptions
    @peripheral_types[key] = type
  end

  def clear_peripheral_types()
    @peripheral_types.clear()
  end

  def generate_peripheral_type_yml()
    peripherals_tree = Hash.new()
    @peripheral_types.each do |name, type|
      peripherals_tree[name] = Array.new() if nil == peripherals_tree[name]
      peripherals_tree[name].push(type.descriptions.to_s)
    end

    File.open("peripherals.yml", 'w') {|f| f.write peripherals_tree.to_yaml }
  end

  protected
  def verify_mismatch(sublist_item, required_hash, actual_hash)
    #overwrite the peripheral_types comparison, only check the mismatch for the description
    if "peripheral_types" == sublist_item
      required_hash.each do |key, required|
        actual = actual_hash[key]
        next if nil == actual

        @result_items[sublist_item] = Hash.new() if nil == @result_items[sublist_item]
        required.set_testresult_parent(@result_items[sublist_item])
        if !required.compare(actual)
          @fail_num = @fail_num + 1
        end
      end
    else
      super(sublist_item, required_hash, actual_hash)
    end
  end

  def compare_attr(attr_name, target)
    if "info" == attr_name and target != nil
      compare_info_attr("part_num", target)
      compare_info_attr("pins_num", target)
      compare_info_attr("package", target)
    else
      super(attr_name, target)
    end
  end

  def save_result(target)
    #overwrite the save result, the chip result should be always recorded even if all pass
    name = "#{@type}-#{@key}---PASS"
    if fail_num > 0
      super(target)
    else
      @result_parent[name] = @result_items
    end
  end

  private
  def compare_info_attr(info_name, target)
    required = @info.instance_variable_get("@" + info_name)
    actual = target.info.instance_variable_get("@" + info_name)
    if !smart_match(required, actual)
      @fail_num = @fail_num + 1
      set_result_attr_fail(info_name, required, actual)
    end
  end
end


class RefChip < Chip
  def initialize(excel_file, info)
    @info = info
    super(excel_file)
  end

  def get_parser()
    @parser = XLSParser.new(@config, @info) if nil == @parser
    return @parser
  end

  def get_info()
    return @info
  end
end


class PeripheralType < ComparableData
  attr_accessor :name, :descriptions

  TYPE = "PeripheralType"

  def initialize()
    @descriptions = Array.new()
    super(TYPE, @name, @descriptions, ["name", "descriptions"], nil)
  end

  def compare_attr(attr_name, target)
    if "descriptions" == attr_name and target != nil
      required_list = instance_variable_get("@" + attr_name)
      actual_list = target.instance_variable_get("@" + attr_name)
      if actual_list != nil
        actual_list.each do |item|
          if !required_list.include?(item)
            @fail_num = @fail_num + 1
            set_result_attr_fail(attr_name, required_list.to_s, item)
          end
        end
      end
    else
      super(attr_name, target)
    end
  end

end

class Pin < ComparableData
  attr_accessor :coords, :port_name, :combined_name

  TYPE = "Pin"

  def initialize()
    @connections = Hash.new()
    super(TYPE, @coords, @port_name, ["coords", "port_name", "combined_name"], ["connections"])
  end

  def set_signal(key, pin_signal)
    if nil == pin_signal
      puts "Fail, pin_signal is null!"
      return
    end

    if !pin_signal.instance_of? PinSignal
      puts "Fail, pin is not a PinSignal instance!"
      return
    end

    orignal_pinsignal = @connections[key]
    if orignal_pinsignal != nil
      # some xml has the multi-alt, for instance, 2 node defined alt1
      # we need merge them
      merge_signal(pin_signal, orignal_pinsignal)
    end

    pin_signal.key = key
    pin_signal.key_description = pin_signal.name
    @connections[key] = pin_signal
  end

  def clear_connections()
    @connections.clear()
  end

  private
  def merge_signal(target, orignal)
    target.name = contact_attr(target.name, orignal.name)
    target.peripheral_instance = contact_attr(target.peripheral_instance, orignal.peripheral_instance)
    target.features = contact_attr(target.features, orignal.features)
  end

  def contact_attr(target_name, orignal_name)
    return nil if nil == target_name or nil == orignal_name

    combined_name = orignal_name
    target_name.split("/").each do | name |
      if !orignal_name.include?(name)
        combined_name =  name + "/" + combined_name
      end
    end

    return combined_name
  end
end


class PinSignal < ComparableData
  attr_accessor :alt_name, :name, :peripheral_instance, :features

  TYPE = "PinSignal"

  def initialize()
    @disallow = Hash.new()
    attrs_val_list = ["alt_name", "name"]
    if $is_peripherial_val
      attrs_val_list.push("peripheral_instance")
    end
    if $is_features_val
      attrs_val_list.push("features")
    end

    super(TYPE, @alt_name, @name, attrs_val_list, ["disallow"])
  end

  def set_disallow(key, port)
    if nil == port
      puts "Fail, port is null!"
      return
    end

    if !port.instance_of? Port
      puts "Fail, port is not a Port instance!"
      return
    end

    port.key = key
    port.key_description = port.register
    @disallow[key] = port
  end

  def clear_disallow()
    @disallow.clear()
  end
end


class Port < ComparableData
  attr_accessor :register

  TYPE = "Port"

  def initialize()
    super(TYPE, @register, @register, ["register"], nil)
  end
end


class DataParser
  def parse(chip)
  end
end