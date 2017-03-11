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
# The excel data from reference manual documentation, which is the reference data.
# This is a parser script to package the excel data to our pin model data.
#
# --- Code author: Haley Guo <hui.guo@nxp.com>
# --- Version added: 0.0.1
#
# ++++++++++++++++
# --- 0.0.1: Haley Guo --- add structure framework, define the interface
#
##########################################################################################
require './pin_model'
require "win32ole"
require "awesome_print"
require 'yaml'

class XLSParser < DataParser
  Header = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  PERIPHERALS_YML = "peripherals.yml"

  def initialize(xls_data_folder, info)
    puts "Parsing excel data ......"
    @xls_data_folder = xls_data_folder
    @info = info
    @xls_data_file = nil
    @peripherals_ref = Hash.new()

    key = /^[A-Z]*\d+?/.match(@info.part_num).to_s
    pattern = Regexp.new("^" + key)

    Dir.foreach(@xls_data_folder) do |file|
      if pattern.match(file) != nil
        path = @xls_data_folder + "/" +file
        if is_find_excel(path)
          @xls_data_file = path
          break
        end
      end
    end
    load() if @xls_data_file != nil
  end


  def is_find_excel(path)
    return false if !File::exists?(path)
    @excel = WIN32OLE::new('excel.Application')
    begin
      workbook = @excel.Workbooks.Open(path)
      partnumWorksheet = workbook.Worksheets(2)
      rows = partnumWorksheet.UsedRange.Rows.Count
      for rowindex in 2..rows
        rdata = partnumWorksheet.Range("A#{rowindex}:D#{rowindex}").Value[0]
        ref_info = get_part_num_info(rdata)

        next if ref_info == nil or ref_info.part_num != @info.part_num

        puts "#{path}"
        if ref_info.pins_num != @info.pins_num
          puts "---Part num package error: Require: #{ref_info.pins_num} -- Actual: #{@info.pins_num}"
          return false
        end
        if ref_info.package != @info.package
          puts "---Part num pins_num error: Require: #{ref_info.package} -- Actual: #{@info.package}"
          return false
        end
        puts "#{rowindex}    #{ref_info.part_num}    #{ref_info.pins_num}    #{ref_info.package}"
        @chip_index = partnumWorksheet.Cells(rowindex,4).Value.to_i-1
        return true

      end
    rescue Exception => ex
      puts ex.message
      puts ex.backtrace
      return false
    ensure
    workbook.Close(0) if workbook != nil
    @excel.Quit()
    end

    puts "Not found the reference data for part number: #{@info.part_num}!"

    return false
  end


  def load()
    @ATL = 8
    @dataTable = Array.new()

    begin
      @excel = WIN32OLE::new('excel.Application')
      workbook = @excel.Workbooks.Open(@xls_data_file)
      pinsWorksheet = workbook.Worksheets(1)
      partnumWorksheet = workbook.Worksheets(2)

      @rows_count = pinsWorksheet.UsedRange.Rows.Count
      @cols_count = pinsWorksheet.UsedRange.Columns.Count
      @MaxHeader = Header[@cols_count-1]

      for rows in 1..@rows_count
        row = pinsWorksheet.Range("A#{rows}:#{@MaxHeader}#{rows}").Value[0]
        #Filter invalid row
        @dataTable.push(row) if is_validrow(row)
      end

      #get index of table header
      @alt_index     = get_alt_index()
      @pinname_index = get_pinname_index()
      if (@pinname_index ==- 1 or @alt_index ==- 1)
        puts "Failed to find message from table header!"
        return false
      end

      puts "part num cols: #{@chip_index}, pin name cols: #{@pinname_index}, alt0 cols: #{@alt_index}" if Chip::DEBUG

      #load peripheral reference data
      @peripherals_ref = YAML.load_file(@xls_data_folder + "/" + PERIPHERALS_YML)

    rescue Exception => ex
      puts "Read excel data error!!"
      puts ex.message
      puts ex.backtrace
      return false
    ensure
      @excel.ActiveWorkbook.Close(0);
      @excel.Quit()
    end

    puts "Read excel data successfully!" if Chip::DEBUG
    return true
  end



  def parse(chip)
    return false if nil == @xls_data_file
    #remove table header
    @dataTable.delete_at(0)
    combined_name_array = Array.new()

    @dataTable.each do |rdata|
      pin = Pin.new()
      pin.coords        = get_coords(rdata)
      pin.port_name     = get_portname(rdata)
      pin.combined_name = ""

      puts "coords: #{pin.coords}  port: #{pin.port_name}"  if Chip::DEBUG

      for alt_index in 0..@ATL
        alt_value = rdata[@alt_index+alt_index]

        #filter invalid alt value
        next if (alt_value == nil or alt_value.length <2)
        #parse signal
        signal = parse_signal(alt_index, alt_value, pin.coords)
        if alt_index < 8
          pin.set_signal(signal.alt_name, signal)
        end
        add_to_array(combined_name_array, signal.name)
      end

      #set alt0 to the default value if the default in excel is not null
      if rdata[@alt_index-1] != nil and rdata[@alt_index-1].to_s.length >= 2
        #K65 exception, if the alt0 is TSIxxx, skip add default
        if !rdata[@alt_index].to_s.include?("TSI")
          default_val = exclude_space(rdata[@alt_index-1])

          if !["DISABLED", "Donotconnect"].include?(default_val)
            signal_def = parse_signal(0, exclude_space(default_val), pin.coords)
            pin.set_signal(signal_def.alt_name, signal_def)
            add_to_array(combined_name_array, signal_def.name)
          end
        end
      end

      #generate combined name
      pin.combined_name = combined_name_array.length==0 ? get_pinname(rdata) : combined_name_array.join("/")
      #clear combined_name buffer
      combined_name_array.clear()
      chip.set_pin(pin.coords, pin)

      puts "combined_name: #{pin.combined_name}\n\r" if Chip::DEBUG
    end

    #load peripheral ref list
    parse_peripheral_type(chip)
    return true
  end

  def add_to_array(combined_name_array, name)
    return if nil == name
    name.to_s.split("/").each do |item|
      combined_name_array.push(item) if !combined_name_array.include?(item)
    end
  end

  def parse_peripheral_type(chip)
    @peripherals_ref.each do |key, des|
      type = PeripheralType.new()
      type.name = key
      type.descriptions = @peripherals_ref[key]
      chip.set_peripheral_type(key, type)
    end
  end

  def parse_signal(alt_index, alt_value, current_coords)
    signal = PinSignal.new()
    signal.alt_name = "alt#{alt_index}"
    signal.name = exclude_space(alt_value)
    signal.peripheral_instance = exclude_space(alt_value.split("_")[0])

    #parse disallow
    port = nil

    @dataTable.each do |rdata|
      coords = get_coords(rdata)
      if coords != current_coords  and rdata.index(alt_value) != nil
        register = get_portname(rdata)
        next if register == nil
        port = Port.new()
        port.register = exclude_space(register)
        signal.set_disallow(port.register, port)
      end

    end

    puts "#{signal.alt_name} - #{signal.name}  ps: #{signal.peripheral_instance}" if Chip::DEBUG
    puts "     disallow - #{port.register}" if Chip::DEBUG and port != nil
    return signal
  end


  def exclude_space(str)
    return str.gsub(/\s/, "")
  end


  def get_portname(rdata)
    port_name = /PT\w\d+/.match(get_pinname(rdata))
    if port_name != nil
      return  exclude_space(port_name.to_s)
    end
    return nil
  end

  def get_pinname(rdata)
     return  exclude_space(rdata[@pinname_index])
  end


  def is_validrow(rdata)
    coords_value = rdata[@chip_index]
    return false if coords_value == nil

    if coords_value.to_s =~ /\w+/
      return true
    else
      return false
    end
  end

  def get_coords(rdata)
      coords = rdata[@chip_index]
      if coords.is_a? Float
        return coords.to_i.to_s
      elsif coords.is_a? String
        return coords
      end
  end

  def get_pinname_index()
    tableHeader = @dataTable[0]
    tableHeader.each do |item|{}
      if (item =~ /Pin.*Name/)
        return tableHeader.index(item)
      end
    end
    return -1
  end

  def get_alt_index()
    tableHeader = @dataTable[0]
    tableHeader.each do |item|{}
      if (item =~  /ALT0/)
        return tableHeader.index(item)
      end
    end
    return -1
  end

  def get_part_num_info(rdata)
    return nil if rdata[0] == nil
    return Chip::Info.new(rdata[0], rdata[1].to_i.to_s, rdata[2])
  end
end


# p = XLSParser.new('C:/SourceCode/cm_val_auto/pin_tool/pin_data_val/kw24.xlsx', nil)
# p.parse_pins()


