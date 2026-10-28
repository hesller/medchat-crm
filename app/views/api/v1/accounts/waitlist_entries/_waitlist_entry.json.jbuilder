json.id entry.id
json.status entry.status
json.specialty entry.specialty
json.expires_at entry.expires_at
json.created_at entry.created_at
json.contact do
  json.id entry.contact.id
  json.name entry.contact.name
  json.phone_number entry.contact.phone_number
end
json.professional do
  json.partial! 'api/v1/accounts/professionals/professional', professional: entry.professional
end if entry.professional
json.offer do
  json.professional do
    json.partial! 'api/v1/accounts/professionals/professional', professional: entry.offered_professional
  end
  json.slot_starts_at entry.offered_slot_starts_at
  json.expires_at entry.offer_expires_at
end if entry.offered?
