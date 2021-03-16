public enum LoginResponse
{
    Successful, LoggedIn, AccountNotFound, InternalError
}
public enum RegistrationResponse
{
    Successful, AccountAlreadyExists, InternalError
}
public enum CreateCharacterResponse
{
    Successful, NameAlreadyExists, InternalError
}
public enum SelectCharacterResponse
{
    Succssful, CharacterNotFound
}