using Mirror;
using UnityEngine;

public class LoginPacket : MessageBase
{
    public string username;
    public string password;
}
public class RegistrationPacket : MessageBase
{
    public string email;
    public string username;
    public string password;
}

public class LoginResponsePacket : MessageBase
{
    public LoginResponse response;
}
public class RegistrationResponsePacket : MessageBase
{
    public RegistrationResponse response;
}

[System.Serializable]
public class CharacterInfo
{
    public int id;
    public string name;
    public float maxHealth;
    public float maxMana;
    public float exp;
    public int profession;
}

public class CharactersPacket : MessageBase
{
    public CharacterInfo[] characters;
}

public class CreateCharacterPacket : MessageBase
{
    public string username;
    public string name;
    public int profession;
}
public class CreateCharacterResponsePacket : MessageBase
{
    public CreateCharacterResponse response;
    public CharacterInfo newCharacter;
}

public class SelectCharacterPacket : MessageBase
{
    public int id;
}
public class SelectCharacterResponsePacket : MessageBase
{
    public SelectCharacterResponse response;
    public CharacterInfo character;
}

[System.Serializable]
public class PlayerInfo
{
    public Vector3 pos;
    public Quaternion rot;
    public CharacterInfo info;
}

public class SpawnPacket : MessageBase
{
    public Vector3 pos;
    public Quaternion rot;
    public int id;
    public string name;
    public int profession;
}

public class InventoryPacket : MessageBase
{
    public InventoryItem[] inventory;
}

public class DroppedItemPacket : MessageBase
{
    public DroppedItem item;
}

public class SpawnAIPacket : MessageBase
{
    public int id;
    public int aiId;
    public Vector3 pos;
    public Quaternion rot;
}
public class DespawnAIPacket : MessageBase
{
    public int id;
}