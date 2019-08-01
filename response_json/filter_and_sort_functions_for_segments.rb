#!/usr/bin/ruby

require 'iso8601'
require 'json'
require 'time'


def all_segments_in_position(data, itineraries, position)
  ret = []
  itineraries.each do |itinerarie|
    ret << data['shop_response_segments'][itinerarie['segment_ids'][position]]
  end
  ret.uniq
end

def filter_itineraries_starting_with(itineraries, picked_segments_ids)
  itineraries.select do |itinerary|
    valid = true
    picked_segments_ids.each_with_index do |picked_segment_id, idx|
      valid = false if picked_segment_id != itinerary['segment_ids'][idx]
    end
    valid
  end
end

def segment_departure_airport(data, segment)
  departure_airport_id = segment['legs'][0]['departure_airport_id']
  data['shop_response_airports'][departure_airport_id]
end

def segment_arrival_airport(data, segment)
  arrival_airport_id = segment['legs'][-1]['arrival_airport_id']
  data['shop_response_airports'][arrival_airport_id]
end



def get_segments(data, picked_segments_ids = [])
  segments = []
  filtered_itineraries = filter_itineraries_starting_with(data['itineraries'], picked_segments_ids)
  all_segments_in_position(data, filtered_itineraries, picked_segments_ids.length).each do |segment|
    segments << {
      zid: segment['zid'],
      from: segment_departure_airport(data, segment)['address']['city_name'],
      to: segment_arrival_airport(data, segment)['address']['city_name'],
      duration: segment['duration'],
      departure_time: segment['legs'][0]['flight_time_range']['from'],
      airlines: segment_airlines(data, segment)
    }
  end
  segments
end

def compare_segments_by_duration(segment_a, segment_b)
  duration_a = ISO8601::Duration.new(segment_a[:duration])
  duration_b = ISO8601::Duration.new(segment_b[:duration])
  duration_a.to_seconds <=> duration_b.to_seconds
end

def compare_segments_by_departure_date(segment_a, segment_b)
  departure_a = Time.parse(segment_a[:departure_time])
  departure_b = Time.parse(segment_b[:departure_time])
  departure_a <=> departure_b
end

def filter_segments_no_stop(data, segments)
  segments.select { |segment| data['shop_response_segments'][segment[:zid]]['legs'].size() <= 1 }
end

def filter_segmets_for_amount_of_stop(data, segments, amount)
  segments.select { |segment| data['shop_response_segments'][segment[:zid]]['legs'].size() == amount }
end

def filter_segmets_by_airlines(data, segments, airline_name)
  segments.select do |segment|
    segment[:airlines].include?(airline_name)
  end
end

def airline_codes(data, segment)
  airline_codes = []
  segment['legs'].each do |leg|
    airline_codes << leg['marketing_airline_code']
  end
  airline_codes
end

def segment_airlines(data, segment)
  airline_names = airline_codes(data, segment).map {|airline_code| data['shop_response_airlines'][airline_code]['name']}
end
