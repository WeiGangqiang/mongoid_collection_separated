require 'spec_helper'

RSpec.describe Mongoid::CollectionSeparated do
  describe 'included' do
    it 'set condition field on condition class' do
      expect(Entry.separated_field).to eq(:form_id)
      expect(Entry.separated_parent_class).to eq(Form)
      expect(Entry.separated_parent_field).to eq(:id)
      expect(Entry.calc_collection_name_fun).to eq(:calc_collection_name)
    end

    it 'use parent field from setting' do
      class MockEntry
        include Mongoid::Document
        include Mongoid::CollectionSeparated
        field :name, type: String

        belongs_to :form

        class << self
          def calc_collection_name form_id
            "#{form_id}_entries"
          end
        end

        separated_by :collection_name, :calc_collection_name, parent_class: 'Form', parent_field: :name
      end

      expect(MockEntry.separated_parent_field).to eq(:name)
      expect(MockEntry.separated_field).to eq(:collection_name)
    end
  end

  describe 'query and persist' do
    context 'query and persist entries form entries collection when collection is not separated' do
      let(:form) {Form.create!}

      it 'when create' do
        form.entries.create name: 'test'
        expect(form.entries.count).to eq(1)
      end

      it 'when build and save' do
        entry = form.entries.build
        entry.name = 'test'
        entry.save
        expect(form.entries.count).to eq(1)
        expect(Entry.count).to eq(1)
        expect(entry.reload.name).to eq('test')
      end

      it 'when update' do
        entry = form.entries.create name: 'test'
        entry.set name: 'change name'
        expect(entry.reload.name).to eq('change name')
        entry.update name: 'another name'
        expect(entry.reload.name).to eq('another name')
      end

      it 'when destroy' do
        entry = form.entries.create
        entry.destroy
        expect(form.entries.count).to eq(0)

        entry = form.entries.create
        form.entries.where(id: entry.id).destroy
        expect(form.entries.count).to eq(0)
      end

      it 'when explain query' do
        query_plan = form.entries.explain.to_h['queryPlanner']
        expect(query_plan['namespace']).to eq("mongoid_test.entries")
      end
    end

    context 'query and persist entries from separated collections when collection is separated' do
      let(:form) {Form.create!}
      before do
        form.entries_separate
      end

      context 'for root document' do
        it 'when create' do
          form.entries.create name: 'test'
          expect(form.entries.count).to eq(1)
          with_new_collection(form) {expect(Entry.count).to eq(1)}
        end

        it 'when build and save' do
          entry = form.entries.build
          entry.name = 'test'
          entry.save
          expect(form.entries.count).to eq(1)
          expect(Entry.count).to eq(0)
          with_new_collection(form) {expect(Entry.count).to eq(1)}
          expect(entry.reload.name).to eq('test')
        end

        it 'when update' do
          entry = form.entries.create
          entry.set name: 'change name'
          with_new_collection form do
            expect(entry.reload.name).to eq('change name')
            entry.update name: 'another name'
            expect(entry.reload.name).to eq('another name')
          end
        end

        it 'when destroy' do
          entry = form.entries.create
          with_new_collection form do
            entry.destroy
            expect(form.entries.count).to eq(0)
          end

          entry = form.entries.create
          with_new_collection form do
            form.entries.where(id: entry.id).destroy
            expect(form.entries.count).to eq(0)
          end
        end

        it 'when touch' do
          entry = form.entries.create
          updated_at = entry.updated_at
          print updated_at
          travel 1.minute do
            entry.touch
          end
          print entry.updated_at
          expect(entry.updated_at).to_not eq(updated_at)
        end

        it 'when query by class and provide object id and class' do
          form.entries.create
          expect(Entry.where(form_id: form.id).count).to eq(1)
          expect(Entry.where(form: form).count).to eq(1)
        end

        it 'when explain query' do
          query = form.entries.explain.to_h['queryPlanner']
          check_query_plan(query, form, 'form_id' => {'$eq' => form.id})

          query = form.entries.where(name: 'test').explain.to_h['queryPlanner']
          check_query_plan(query, form, '$and' => [{'form_id' => {'$eq' => form.id}}, {'name' => {'$eq' => 'test'}}])

          query = Entry.where(form: form).explain.to_h['queryPlanner']
          check_query_plan(query, form, 'form_id' => {'$eq' => form.id})

          query = Entry.where(form: form, name: 'test').explain.to_h['queryPlanner']
          check_query_plan(query, form, '$and' => [{'form_id' => {'$eq' => form.id}}, 'name' => {'$eq' => 'test'}])
        end

        it 'when aggregate and provide form id as match condition' do
          expect(form.entries.ensured_collection.name).to eq("entries_#{form.id}")
        end

        it 'when using in query and there is only one query name' do
          form.entries.create
          entries = Entry.in(form_id: [form.id]).to_a
          expect(entries.count).to eq(1)
        end

      end

      context 'for embedded document' do
        it 'when create' do
          entry = form.entries.create name: 'test'
          entry.create_metainfo device: 'iphone'
          expect(entry.reload.metainfo.device).to eq('iphone')
        end

        it 'when build and save' do
          entry = form.entries.build
          entry.name = 'test'
          entry.metainfo = Metainfo.new(device: 'iphone')
          entry.save
          expect(entry.reload.metainfo.device).to eq('iphone')
        end

        it 'when update' do
          entry = form.entries.create metainfo: {device: 'xiaomi'}
          entry.set metainfo: {device: 'iphone'}
          expect(entry.reload.metainfo.device).to eq('iphone')

          entry.metainfo.device = 'huawei'
          entry.save
          expect(entry.reload.metainfo.device).to eq('huawei')
        end

        it 'when query by class and provide object id and class' do
          form.entries.create metainfo: {device: 'iphone'}
          expect(Entry.where(form_id: form.id, 'metainfo.device' => 'iphone').count).to eq(1)
          expect(Entry.where(form: form).count).to eq(1)
        end


        it 'when aggregate and provide form id as match condition' do
          expect(form.entries.ensured_collection.name).to eq("entries_#{form.id}")
        end
      end
    end
  end

  def check_query_plan(query_plan, form, query)
    expect(query_plan['namespace']).to eq("mongoid_test.entries_#{form.id}")
    expect(query_plan['parsedQuery']).to eq(query)
  end

  def with_new_collection form
    Entry.with(collection: "entries_#{form.id}") {yield}
  end

end
