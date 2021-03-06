# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'spec_helper'

include TwitterCldr::Localized

describe LocalizedString do
  describe '#%' do
    context 'when argument is not a Hash' do
      it 'performs regular formatting of values' do
        ('%d is an integer'.localize % 3.14).should == '3 is an integer'
      end

      it 'performs regular formatting of arrays' do
        ('"% 04d" is a %s'.localize % [12, 'number']).should == '" 012" is a number'
      end

      it 'ignores pluralization placeholders' do
        ('%s: %{horses_count:horses}'.localize % 'total').should == 'total: %{horses_count:horses}'
      end

      it 'raises ArgumentError when the string contains named placeholder' do
        lambda { '%{msg}: %{horses_count:horses}'.localize % 'total' }.should raise_error(ArgumentError)
      end
    end

    context 'when argument is a Hash' do
      let(:horses) { { :one => '1 horse', :other => '%{horses_count} horses' } }

      before(:each) do
        stub(TwitterCldr::Formatters::Plurals::Rules).rule_for { |n, _| n == 1 ? :one : :other  }
      end

      it 'interpolates named placeholders' do
        ('%<num>.2f is a %{noun}'.localize % { :num => 3.1415, :noun => 'number' }).should == '3.14 is a number'
      end

      it 'performs regular pluralization' do
        ('%{horses_count:horses}'.localize % { :horses_count => 2, :horses => horses }).should == '2 horses'
      end

      it 'performs inline pluralization' do
        string = '%<{ "horses_count": { "other": "%{horses_count} horses" } }>'.localize
        (string % { :horses_count => 2 }).should == '2 horses'
      end

      it 'performs both formatting and regular pluralization simultaneously' do
        string = '%{msg}: %{horses_count:horses}'.localize
        (string % { :horses_count => 2, :horses => horses, :msg => 'result' }).should == 'result: 2 horses'
      end

      it 'performs both formatting and inline pluralization simultaneously' do
        string = '%{msg}: %<{"horses_count": {"other": "%{horses_count} horses"}}>'.localize
        (string % { :horses_count => 2, :msg => 'result' }).should == 'result: 2 horses'
      end

      it 'performs both formatted interpolation and inline pluralization simultaneously' do
        string = '%<number>d, %<{"horses_count": {"other": "%{horses_count} horses" }}>'.localize
        (string % { :number => 3.14, :horses_count => 2 }).should == '3, 2 horses'
      end

      it 'leaves regular pluralization placeholders unchanged if not enough information given' do
        string = '%{msg}: %{horses_count:horses}'.localize
        (string % { :msg => 'no pluralization' } ).should == 'no pluralization: %{horses_count:horses}'
      end

      it 'leaves inline pluralization placeholders unchanged if not enough information given' do
        string = '%<number>d, %<{"horses_count": {"one": "one horse"}}>'.localize
        (string % { :number => 3.14, :horses_count => 2 }).should == '3, %<{"horses_count": {"one": "one horse"}}>'
      end

      it 'raises KeyError when value for a named placeholder is missing' do
        lambda do
          '%{msg}: %{horses_count:horses}'.localize % { :horses_count => 2, :horses => horses }
        end.should raise_error(KeyError)
      end
    end
  end

  describe "#to_s" do
    it "should return a copy the base string" do
      string = "galoshes"
      result = string.localize.to_s

      result.should == string
      result.equal?(string).should_not be_true
    end
  end

  describe "#to_f" do
    it "should correctly parse a number with a thousands separator" do
      "1,300".localize.to_f.should == 1300.0
      "1.300".localize(:es).to_f.should == 1300.0
    end

    it "should correctly parse a number with a decimal separator" do
      "1.300".localize.to_f.should == 1.3
      "1,300".localize(:es).to_f.should == 1.3
    end

    it "should correctly parse a number with a thousands and a decimal separator" do
      "1,300.05".localize.to_f.should == 1300.05
      "1.300,05".localize(:es).to_f.should == 1300.05
    end

    it "should return zero if the string contains no numbers" do
      "abc".localize.to_f.should == 0.0
    end

    it "should return only the numbers at the beginning of the string if the string contains any non-numeric characters" do
      "1abc".localize.to_f.should == 1.0
      "a1bc".localize.to_f.should == 0.0
    end
  end

  describe "#to_i" do
    it "should chop off the decimal" do
      "1,300.05".localize.to_i.should == 1300
      "1.300,05".localize(:es).to_i.should == 1300
    end
  end

  describe "#normalize" do
    let(:string) { 'string' }
    let(:normalized_string) { 'normalized' }
    let(:localized_string) { string.localize }

    it 'returns a LocalizedString' do
      localized_string.normalize.should be_an_instance_of(LocalizedString)
    end

    it 'it uses NFD by default' do
      mock(Eprun).normalize(string, :nfd) { normalized_string }
      localized_string.normalize.base_obj.should == normalized_string
    end

    it "uses specified algorithm if there is any" do
      mock(Eprun).normalize(string, :nfkd) { normalized_string }
      localized_string.normalize(:using => :NFKD).base_obj.should == normalized_string
    end

    it "raises an ArgumentError if passed an unsupported normalization form" do
      lambda { localized_string.normalize(:using => :blarg) }.should raise_error(ArgumentError)
    end
  end

  describe "#casefold" do
    it 'returns a LocalizedString' do
      str = "Weißrussland".localize.casefold
      str.should be_an_instance_of(LocalizedString)
      str.to_s.should == "weissrussland"
    end

    it 'does not pass the t option by default' do
      "Istanbul".localize.casefold.to_s.should == "istanbul"
    end

    it 'uses the t option when explicitly given' do
      "Istanbul".localize.casefold(:t => true).to_s.should == "ıstanbul"
    end

    it 'uses t by default if the locale is tr (az not supported)' do
      "Istanbul".localize(:tr).casefold.to_s.should == "ıstanbul"
    end
  end

  describe "#each_sentence" do
    it "returns an enumerator if not passed a block" do
      "foo bar".localize.each_sentence.should be_a(Enumerator)
    end

    it "yields sentences as localized strings" do
      str = "Quick. Brown. Fox.".localize

      str.each_sentence do |sentence|
        sentence.should be_a(LocalizedString)
      end

      str.each_sentence.to_a.map(&:to_s).should == [
        "Quick.", " Brown.", " Fox."
      ]
    end
  end

  describe "#code_points" do
    it "returns an array of Unicode code points for the string" do
      "español".localize.code_points.should == [0x65, 0x73, 0x70, 0x61, 0xF1, 0x6F, 0x6C]
    end
  end

  describe "#each_char" do
    it "iterates over each character in the string if a block is given" do
      index = 0
      str = "twitter"

      str.localize.each_char do |char|
        str.chars.to_a[index].should == char
        index += 1
      end
    end

    it "returns an enumerator if no block is given" do
      "twitter".localize.each_char.should be_a(Enumerator)
    end

    it "responds to a few other methods from Enumerable" do
      upcased = "twitter".localize.map { |letter| letter.upcase }
      upcased.size.should == 7
      upcased.join.should == "TWITTER"

      "twitter".localize.inject("") { |str, letter| str = "#{letter}#{str}"; str }.should == "rettiwt"
    end
  end

  describe "#to_yaml" do
    it "should be able to successfully roundtrip the string" do
      YAML.load("coolio".localize.to_yaml).should == "coolio"
      YAML.load("coolió".localize.to_yaml).should == "coolió"
    end
  end

  describe "#to_bidi" do
    it "should return an instance of TwitterCldr::Shared::Bidi" do
      "abc".localize.to_bidi.should be_a(TwitterCldr::Shared::Bidi)
    end
  end

  describe "#to_reordered_s" do
    it "should reverse the order a basic RTL string" do
      str = "{0} \331\210 {1}".gsub("{0}", "a").gsub("{1}", "b")
      chars = str.chars.to_a
      chars.first.should == "a"
      chars.last.should == "b"

      result = str.localize.to_reordered_s(:direction => :RTL)
      result_chars = result.chars.to_a
      result_chars.first.should == "b"
      result_chars.last.should == "a"
    end
  end

end