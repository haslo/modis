require 'spec_helper'

module PersistenceSpec
  class MockModel
    include Modis::Model

    attribute :name, :string, default: 'Ian'
    validates :name, presence: true

    before_create :test_before_create
    after_create :test_after_create

    before_update :test_before_update
    after_update :test_after_update

    before_save :test_before_save
    after_save :test_after_save

    def called_callbacks
      @called_callbacks ||= []
    end

    def test_after_create
      called_callbacks << :test_after_create
    end

    def test_before_create
      called_callbacks << :test_before_create
    end

    def test_after_update
      called_callbacks << :test_after_update
    end

    def test_before_update
      called_callbacks << :test_before_update
    end

    def test_after_save
      called_callbacks << :test_after_save
    end

    def test_before_save
      called_callbacks << :test_before_save
    end
  end
end

describe Modis::Persistence do
  let(:model) { PersistenceSpec::MockModel.new }

  describe 'namespaces' do
    it 'returns the namespace' do
      PersistenceSpec::MockModel.namespace.should eq 'persistence_spec:mock_model'
    end

    it 'returns the absolute namespace' do
      PersistenceSpec::MockModel.absolute_namespace.should eq 'modis:persistence_spec:mock_model'
    end

    it 'allows the namespace to be set explicitly' do
      PersistenceSpec::MockModel.namespace = 'other'
      PersistenceSpec::MockModel.absolute_namespace.should eq 'modis:other'
    end

    after { PersistenceSpec::MockModel.namespace = nil }
  end

  it 'returns a key' do
    model.save!
    model.key.should eq 'modis:persistence_spec:mock_model:1'
  end

  it 'returns a nil key if not saved' do
    model.key.should be_nil
  end

  it 'works with ActiveModel dirty tracking' do
    expect { model.name = 'Kyle' }.to change(model, :changed).to(['name'])
    model.name_changed?.should be_true
  end

  it 'resets dirty tracking when saved' do
    model.name = 'Kyle'
    model.name_changed?.should be_true
    model.save!
    model.name_changed?.should be_false
  end

  it 'resets dirty tracking when created' do
    model = PersistenceSpec::MockModel.create!(name: 'Ian')
    model.name_changed?.should be_false
  end

  it 'is persisted' do
    model.persisted?.should be_true
  end

  it 'does not track the ID if the underlying Redis command failed'

  describe 'callbacks' do
    it 'preserves dirty state for the duration of the callback life cycle'
    it 'halts the chain if a callback returns false'

    describe 'a new record' do
      it 'calls the before_create callback' do
        model.save!
        model.called_callbacks.should include(:test_before_create)
      end

      it 'calls the after create callback' do
        model.save!
        model.called_callbacks.should include(:test_after_create)
      end
    end

    describe 'an existing record' do
      before { model.save! }

      it 'calls the before_update callback' do
        model.save!
        model.called_callbacks.should include(:test_before_update)
      end

      it 'calls the after update callback' do
        model.save!
        model.called_callbacks.should include(:test_after_update)
      end
    end

    it 'calls the before_save callback' do
      model.save!
      model.called_callbacks.should include(:test_before_save)
    end

    it 'calls the after save callback' do
      model.save!
      model.called_callbacks.should include(:test_after_save)
    end
  end

  describe 'create' do
    it 'resets dirty tracking' do
      model = PersistenceSpec::MockModel.create(name: 'Ian')
      model.name_changed?.should be_false
    end
  end

  describe 'create!' do
    it 'raises an error if the record could not be saved' do
      model.name = nil
      expect { model.save! }.to raise_error(Modis::RecordNotSaved)
    end
  end
end
