require 'spec_helper'

describe Ian do
  it 'has a version number' do
    expect(Ian::VERSION).not_to be nil
  end

  it 'give the location of the DEBIAN path' do
    expect(File.basename(Ian.debpath("/tmp"))).to eq("DEBIAN")
  end
end
