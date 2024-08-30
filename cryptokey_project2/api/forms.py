# forms.py
from django import forms
from .models import PasswordEntry, SecureNote, CreditCard, IdentityCard, EncryptionKey

class PasswordForm(forms.ModelForm):
    class Meta:
        model = PasswordEntry
        fields = ['url', 'username', 'password']

class SecureNoteForm(forms.ModelForm):
    class Meta:
        model = SecureNote
        fields = ['note']

class CreditCardForm(forms.ModelForm):
    class Meta:
        model = CreditCard
        fields = ['card_number', 'expiry_date', 'cvv']

class IdentityCardForm(forms.ModelForm):
    class Meta:
        model = IdentityCard
        fields = ['card_number', 'expiry_date', 'cvv']

class EncryptionKeyForm(forms.ModelForm):
    class Meta:
        model = EncryptionKey
        fields = ['S', 'expiry_date', ]
