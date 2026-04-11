from django.contrib import admin

from .models import Material


@admin.register(Material)
class MaterialAdmin(admin.ModelAdmin):
	list_display = ("id", "title", "subject", "owner", "created_at")
	list_filter = ("subject", "owner")
	search_fields = ("title", "description")
