class Lotteries::EntrantServiceDetailValidator < ActiveModel::Validator
  def validate(service_detail)
    @service_detail = service_detail
    validate_accepted
    validate_rejected
    validate_under_review
  end

  private

  attr_reader :service_detail
  delegate :errors, to: :service_detail, private: true

  def validate_accepted
    return unless service_detail.form_accepted_at?

    errors.add(:completed_date, "must be present") if service_detail.completed_date.blank?
    errors.add(:form_rejected_at, "may not be present") if service_detail.form_rejected_at.present?
    errors.add(:form_rejected_comments, "may not be present") if service_detail.form_rejected_comments.present?
  end

  def validate_rejected
    return unless service_detail.form_rejected_at?

    errors.add(:form_rejected_comments, "must be present") if service_detail.form_rejected_comments.blank?
    errors.add(:form_accepted_at, "may not be present") if service_detail.form_accepted_at.present?
    errors.add(:form_accepted_comments, "may not be present") if service_detail.form_accepted_comments.present?
    errors.add(:completed_date, "may not be present") if service_detail.completed_date.present?
  end

  def validate_under_review
    return if service_detail.form_accepted_at? || service_detail.form_rejected_at?

    errors.add(:form_accepted_comments, "may not be present") if service_detail.form_accepted_comments.present?
    errors.add(:form_rejected_comments, "may not be present") if service_detail.form_rejected_comments.present?
    errors.add(:completed_date, "may not be present") if service_detail.completed_date.present?
  end
end
