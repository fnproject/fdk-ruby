require 'fdk'

def myfunction(context:, input:)
    # below statement is to lazy load oci as "require 'oci'" will take long time due to the huge size of oci gem(3.5+ mb)
    autoload(:OCI, 'oci')
    input_value = input.respond_to?(:fetch) ? input.fetch('compartmentId') : input
    compartment_id = input_value.to_s.strip.empty? ? '' : input_value
    rps = OCI::Auth::Signers.resource_principals_signer
    identity_client = OCI::Identity::IdentityClient.new(signer: rps)
    compartment_id_from_identity_client = identity_client.get_compartment(compartment_id).data.id
    { compartmentId: "#{compartment_id_from_identity_client}"}
end

FDK.handle(target: :myfunction)