json.payload do
  json.array! @entries do |entry|
    json.partial! 'api/v1/accounts/waitlist_entries/waitlist_entry', entry: entry
  end
end
