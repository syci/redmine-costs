require File.dirname(__FILE__) + '/../spec_helper'

describe User, "#destroy" do
  let(:user) { Factory.create(:user) }
  let(:user2) { Factory.create(:user) }
  let(:substitute_user) { DeletedUser.first }
  let(:project) { Factory.create(:valid_project) }

  before do
    user
    user2
  end

  shared_examples_for "updated journalized associated object" do
    before do
      User.current = user2
      associations.each do |association|
        associated_instance.send(association.to_s + "=", user2)
      end
      associated_instance.save!

      User.current = user # in order to have the content journal created by the user
      associated_instance.reload
      associations.each do |association|
        associated_instance.send(association.to_s + "=", user)
      end
      associated_instance.save!

      user.destroy
      associated_instance.reload
    end

    it { associated_class.find_by_id(associated_instance.id).should == associated_instance }
    it "should replace the user on all associations" do
      associations.each do |association|
        associated_instance.send(association).should == substitute_user
      end
    end
    it { associated_instance.journals.first.user.should == user2 }
    it "should update first journal changes" do
      associations.each do |association|
        associated_instance.journals.first.changes[association.to_s + "_id"].last.should == user2.id
      end
    end
    it { associated_instance.journals.last.user.should == substitute_user }
    it "should update second journal changes" do
      associations.each do |association|
        associated_instance.journals.last.changes[association.to_s + "_id"].last.should == substitute_user.id
      end
    end
  end

  shared_examples_for "created journalized associated object" do
    before do
      User.current = user # in order to have the content journal created by the user
      associations.each do |association|
        associated_instance.send(association.to_s + "=", user)
      end
      associated_instance.save!

      User.current = user2
      associated_instance.reload
      associations.each do |association|
        associated_instance.send(association.to_s + "=", user2)
      end
      associated_instance.save!

      user.destroy
      associated_instance.reload
    end

    it { associated_class.find_by_id(associated_instance.id).should == associated_instance }
    it "should keep the current user on all associations" do
      associations.each do |association|
        associated_instance.send(association).should == user2
      end
    end
    it { associated_instance.journals.first.user.should == substitute_user }
    it "should update the first journal" do
      associations.each do |association|
        associated_instance.journals.first.changes[association.to_s + "_id"].last.should == substitute_user.id
      end
    end
    it { associated_instance.journals.last.user.should == user2 }
    it "should update the last journal" do
      associations.each do |association|
        associated_instance.journals.last.changes[association.to_s + "_id"].first.should == substitute_user.id
        associated_instance.journals.last.changes[association.to_s + "_id"].last.should == user2.id
      end
    end
  end

  describe "WHEN the user updated a cost object" do
    let(:associations) { [:author] }
    let(:associated_instance) { Factory.build(:variable_cost_object) }
    let(:associated_class) { CostObject }

    it_should_behave_like "updated journalized associated object"
  end

  describe "WHEN the user created a cost object" do
    let(:associations) { [:author] }
    let(:associated_instance) { Factory.build(:variable_cost_object) }
    let(:associated_class) { CostObject }

    it_should_behave_like "created journalized associated object"
  end

  describe "WHEN the user is part of a group" do
    let(:group) { Factory.create(:group) }
    let(:group_user) { Factory.create(:group_user, :group => group,
                                                   :user => user) }
    before do
      group_user

      user.destroy
    end

    it { Group.find_by_id(group.id).should == group }
    it { GroupUser.find_by_id(group_user.id).should be_nil }
  end

  describe "WHEN the user has a labor_budget_item associated" do
    let(:item) { Factory.build(:labor_budget_item, :user => user) }

    before do
      item.save!

      user.destroy
    end

    it { LaborBudgetItem.find_by_id(item.id).should == item }
    it { item.user_id.should == user.id }
  end

  describe "WHEN the user has a cost entry" do
    let(:issue) { Factory.create(:valid_issue) }
    let(:entry) { Factory.build(:cost_entry, :user => user,
                                             :project => issue.project,
                                             :units => 100.0,
                                             :spent_on => Date.today,
                                             :issue => issue,
                                             :comments => "") }

    before do
      Factory.create(:member, :project => issue.project,
                              :user => user,
                              :roles => [Factory.build(:role)])
      entry.save!

      user.destroy

      entry.reload
    end

    it { entry.user_id.should == user.id }
  end

  describe "WHEN the user is assigned an hourly rate" do
    let(:hourly_rate) { Factory.build(:hourly_rate, :user => user,
                                                    :project => project) }

    before do
      hourly_rate.save!
      user.destroy
    end

    it { HourlyRate.find_by_id(hourly_rate.id).should == hourly_rate }
    it { hourly_rate.reload.user_id.should == user.id }
  end

  describe "WHEN the user is assigned a default hourly rate" do
    let(:default_hourly_rate) { Factory.build(:default_hourly_rate, :user => user,
                                                                    :project => project) }

    before do
      default_hourly_rate.save!
      user.destroy
    end

    it { DefaultHourlyRate.find_by_id(default_hourly_rate.id).should == default_hourly_rate }
    it { default_hourly_rate.reload.user_id.should == user.id }
  end
end