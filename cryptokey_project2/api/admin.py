from django.contrib import admin
from .models import PasswordEntry, SecureNote, CreditCard, IdentityCard, EncryptionKey

admin.site.register(PasswordEntry)
admin.site.register(SecureNote)
admin.site.register(CreditCard)
admin.site.register(IdentityCard)
admin.site.register(EncryptionKey)