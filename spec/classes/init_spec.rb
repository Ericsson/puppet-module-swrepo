require 'spec_helper'
describe 'swrepo' do

  context 'with defaults for all parameters' do
    it { should contain_class('swrepo') }
  end
end
