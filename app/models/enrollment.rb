class Enrollment < ActiveRecord::Base
  include Actionable
  
  belongs_to :klass, :counter_cache => true
  belongs_to :student
  belongs_to :paid_by, :polymorphic => true

  # Scopes
  scope :for, ->(course, user) {
    joins(:klass).joins(:student).where('klasses.course_id = :course_id and students.user_id = :user_id and enrollments.active = TRUE', 
    :course_id => course.id, :user_id => user.id)
  }  
    
  # callbacks
  after_create do
    if klass.private && self.invited_at.present?
      activity = 'invited'
    else
      klass.increment!(:active_enrollments)
      activity = 'enrolled'
    end

    log_activity(activity, klass, student, klass.course.name)
  end


  after_update do |enrollment|
    unless self.changes[:last_attended_at].present?
      activity = nil
    
      if self.active
        klass.increment!(:active_enrollments) unless self.changes[:active][0]
      else
        klass.decrement!(:active_enrollments) if self.changes[:active] && self.changes[:active][0]
      end

      if enrollment.active 
        if self.accepted_or_declined_at.present? && self.changes[:accepted_or_declined_at] && self.changes[:accepted_or_declined_at][0].blank?
          activity = 'accepted'
        end

        if enrollment.dropped_at.blank? && self.changes[:dropped_at] && self.changes[:dropped_at][0].present?
          activity = 'enrolled'
        end
      else
        if enrollment.dropped_at.present? && self.changes[:dropped_at] && self.changes[:dropped_at][0].blank?
          activity = 'dropped'
        end

        if enrollment.accepted_or_declined_at.present? && self.changes[:accepted_or_declined_at] && self.changes[:accepted_or_declined_at][0].blank?
          activity = 'declined'
        end

        if enrollment.suspended_at.present? && self.changes[:suspended_at] && self.changes[:suspended_at][0].blank?
          activity = 'suspended'
        end
      end

      if activity.present?
        log_activity(activity, klass, student, klass.course.name)
      end
    end
  end
end