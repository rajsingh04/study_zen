from django.db import models


class Material(models.Model):
	title = models.CharField(max_length=255)
	description = models.TextField(blank=True)
	file = models.FileField(upload_to="materials/%Y/%m/%d/", null=True, blank=True)
	owner = models.ForeignKey("authentication.User", on_delete=models.CASCADE, related_name="materials")
	subject = models.ForeignKey(
		"subject.Subject",
		on_delete=models.CASCADE,
		related_name="materials",
		null=True,
		blank=True,
	)
	created_at = models.DateTimeField(auto_now_add=True)

	def __str__(self):
		return self.title
