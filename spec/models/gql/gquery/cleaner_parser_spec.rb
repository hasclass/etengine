require 'spec_helper'

module Gql

describe Gquery::CleanerParser do
  describe "#clean" do
    it "should remove gql-modifier (present/future/stored)" do
      str = Gquery::CleanerParser.clean("future:SUM(foo)")
      str.should == "SUM(foo)"
    end

    it "should remove gql-modifier with underscore" do
      str = Gquery::CleanerParser.clean("future_lv:SUM(foo)")
      str.should == "SUM(foo)"
    end

    it "should remove whitespace" do
      str = Gquery::CleanerParser.clean("foo bar\t\n\r\n\t baz")
      str.should == "foobarbaz"
    end

    it "should remove comments" do
      str = Gquery::CleanerParser.clean("foo/*comment*/b*a/r/*secondcomment*/baz")
      str.should == "foob*a/rbaz"
    end
  end
end

end# Gql
