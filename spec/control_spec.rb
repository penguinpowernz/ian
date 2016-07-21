require 'spec_helper'


describe Ian::Control do
  context "a default control file" do
    let(:ctrl) { Ian::Control.default }
  
    it "should have all mandatory fields by default" do
      expect(ctrl.missing_mandatory_fields).to be_empty  
    end
  
    it "should be valid by default" do
      expect(ctrl).to be_valid
    end
  
    it "should not allow to delete a mandatory field" do
      expect {
        ctrl.delete(:package)
      }.to raise_error(ArgumentError)
    end
    
    it "should allow to delete a non mandatory field" do
      expect(ctrl[:essential]).to eq "no"
      
      expect {
        ctrl.delete(:essential)
      }.to_not raise_error
      
      expect(ctrl[:essential]).to be_nil
    end
  
    it "should be able to update valid fields" do
      ctrl.update(package: "blek", version: "4.4")
      expect(ctrl[:package]).to eq "blek"
      expect(ctrl[:version]).to eq "4.4"
      
      ctrl[:package] = "horse"
      expect(ctrl[:package]).to eq "horse"      
    end
    
    it "should not be able to update invalid fields" do
      expect {
        ctrl.update(potato: "blek", version: "4.4")
      }.to raise_error(ArgumentError)
      
      expect {
        ctrl[:potato] = "4.4"
      }.to raise_error(ArgumentError)

    end
  end
end
