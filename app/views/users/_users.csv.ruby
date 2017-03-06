CSV.generate do |csv|
    attributes = %w(email first_name last_name confirmed_at)
    csv << attributes
    @users.each do |user|
        csv << attributes.map { |attr| user.send(attr) }
    end
end
