from .models import Subject
from rest_framework import serializers


class SubjectSerializer(serializers.ModelSerializer):
    # Expose a simple owner_name field derived from the related user
    # so the client can show who created the subject without doing
    # extra lookups.
    owner_name = serializers.CharField(source="owner.username", read_only=True)

    class Meta:
        model = Subject
        fields = [
            "id",
            "name",
            "description",
            "owner",  # this will be the owner_id, set server-side
            "enrolled_students",
            "is_completed",
            "owner_name",
        ]
        # These are managed by the server and should not be required
        # in the request payload when creating or updating subjects.
        read_only_fields = [
            "id",
            "owner",
            "enrolled_students",
            "owner_name",
        ]