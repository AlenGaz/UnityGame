using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Mirror;
using UnityEngine.SceneManagement;
using UnityEditor;
using Mirror.Websocket;
using Org.BouncyCastle.Bcpg;
using System;

public class NetworkingManager : NetworkManager
{
    public static NetworkingManager getInstance;
    public override void Awake()
    {
        if (getInstance == null)
        {
            getInstance = this;
            DontDestroyOnLoad(gameObject);
        }
        else
        {
            print("destroying new networking manager");
            Destroy(gameObject);
        }

        base.Awake();
    }

    [SerializeField] GameObject databasePrefab;
    [SerializeField] GameObject _playerPrefab;
    [SerializeField] bool host = true;







    public DatabaseManager database { get; private set; }

    List<Account> accounts = new List<Account>();
    List<Player> players = new List<Player>();
    bool isServer;
    Dictionary<int, _Player> clientPlayers = new Dictionary<int, _Player>();
    Dictionary<int, _Player> serverPlayers = new Dictionary<int, _Player>();


    //public static event Action<NetworkConnection> RelayOnServerAddPlayer;

    public override void OnStartServer()
    {
        if (!host)
            SceneManager.LoadScene(1);

        SpawnDatabase();
        isServer = true;
        NetworkServer.RegisterHandler<LoginPacket>(OnLogin);
        NetworkServer.RegisterHandler<RegistrationPacket>(OnRegistration);
        NetworkServer.RegisterHandler<CreateCharacterPacket>(OnCreateCharacter);
        NetworkServer.RegisterHandler<SelectCharacterPacket>(OnSelectCharacter);


        //GameObject.Find("Server Spawner").gameObject.active = true;
    }

    public override void OnStartClient()
    {
        isServer = false;
        NetworkClient.RegisterHandler<LoginResponsePacket>(OnLoginResponse, false);
        NetworkClient.RegisterHandler<RegistrationResponsePacket>(OnRegistrationResponse, false);
        NetworkClient.RegisterHandler<CreateCharacterResponsePacket>(OnCreateCharacterResponse, false);
        NetworkClient.RegisterHandler<SelectCharacterResponsePacket>(OnSelectCharacterResponse, false);
        NetworkClient.RegisterHandler<CharactersPacket>(OnCharacterPacket, false);
        NetworkClient.RegisterHandler<SpawnPacket>(OnPlayerSpawn, false);
        NetworkClient.RegisterHandler<InventoryPacket>(OnInventoryUpdate, false);
        NetworkClient.RegisterHandler<SpawnAIPacket>(OnSpawnAI, false);
        NetworkClient.RegisterHandler<DespawnAIPacket>(OnDespawnAI, false);
        //GameObject.Find("Client Spawner").gameObject.active = true;
    }

    /*public override void OnServerAddPlayer(NetworkConnection conn)
    {
        base.OnServerAddPlayer(conn);
        RelayOnServerAddPlayer?.Invoke(conn);
    }

    /*public override void OnServerDisconnect(NetworkConnection conn)
    {
        base.OnServerDisconnect(conn);
    }*/


    void OnLevelWasLoaded(int level)
    {
        if (level == 1 && isServer)
            ItemDatabase.getInstance.InitDroppedItems();
    }

    public override void OnServerDisconnect(NetworkConnection conn)
    {
       
        var objects = conn.clientOwnedObjects;
        if (objects != null && objects.Count > 0)
        {
         
            foreach (var obj in objects)
            {
                _Player player = obj.GetComponent<_Player>();
                
                if (player != null)
                {
                    
                    database.SaveCharacter(player.OnDisconnection());

                    foreach (var p in serverPlayers)
                    {
                        if (p.Value.con == conn)
                        {
                            serverPlayers.Remove(p.Key);
                            NetworkServer.Destroy(p.Value.gameObject);
                            Debug.Log(p.Value.gameObject.name + ": Key:" + p.Key + ": DISCONNECTED");

                            return;
                        }
                    }
                    return;
                }
            }
        }

       
    }

    void SpawnDatabase()
    {
        GameObject go = Instantiate(databasePrefab, transform);
        database = go.GetComponent<DatabaseManager>();
        database.Init();
    }

    void OnLogin(NetworkConnection connection, LoginPacket packet)
    {
        string _chars = "";
        LoginResponse resp = database.Login(packet.username, packet.password, ref _chars);
        LoginResponsePacket p = new LoginResponsePacket { response = resp };
        connection.Send(p);

        if (resp == LoginResponse.Successful)
        {
            accounts.Add(new Account
            {
                connection = connection,
                username = packet.username,
                password = packet.password
            });

            CharactersPacket _p = new CharactersPacket();
            List<CharacterInfo> chars = new List<CharacterInfo>();
            if (!string.IsNullOrEmpty(_chars))
            {
                foreach (string c in _chars.Split(';'))
                {
                    int _c = int.Parse(c);
                    CharacterInfo cInfo = database.LoadCharacter(_c);
                    if (cInfo != null)
                        chars.Add(cInfo);
                }

                _p.characters = new CharacterInfo[chars.Count];
                for (int i = 0; i < chars.Count; i++)
                    _p.characters[i] = chars[i];
            }

            connection.Send(_p);
        }
    }
    void OnRegistration(NetworkConnection connection, RegistrationPacket packet)
    {
        RegistrationResponse resp = database.Register(packet.email, packet.username, packet.password);
        RegistrationResponsePacket p = new RegistrationResponsePacket { response = resp };
        connection.Send(p);
    }

    void OnLoginResponse(NetworkConnection connection, LoginResponsePacket packet)
    {
        LoginManager.getInstance.LoginResponse(packet.response);
    }
    void OnRegistrationResponse(NetworkConnection connection, RegistrationResponsePacket packet)
    {
        RegistrationManager.getInstance.RegistrationResponse(packet.response);
    }

    void OnCreateCharacter(NetworkConnection connection, CreateCharacterPacket packet)
    {
        int id = -1;
        CreateCharacterResponse resp = database.CreateCharacter(packet.username, packet.name, packet.profession, ref id);
        CreateCharacterResponsePacket p = new CreateCharacterResponsePacket();
        p.response = resp;

        if (resp == CreateCharacterResponse.Successful)
        {
            p.newCharacter = new CharacterInfo
            {
                id = id,
                name = packet.name,
                profession = packet.profession,
            };
            
        }
        else
            p.newCharacter = new CharacterInfo();

        connection.Send(p);
    }
    void OnCreateCharacterResponse(NetworkConnection connection, CreateCharacterResponsePacket packet)
    {
        if (packet.response == CreateCharacterResponse.Successful)
            CharacterSelection.getInstance.GetCharacter(packet.newCharacter);
    }

    void OnSelectCharacter(NetworkConnection connection, SelectCharacterPacket packet)
    {
        CharacterInfo info = database.LoadCharacter(packet.id);
        SelectCharacterResponsePacket p = new SelectCharacterResponsePacket();
        p.response = info != null ? SelectCharacterResponse.Succssful : SelectCharacterResponse.CharacterNotFound;
        p.character = info != null ? info : new CharacterInfo();
        connection.Send(p);
        if (info != null)
        {
            players.Add(new Player
            {
                account = accounts.Find(x => x.connection == connection),
                info = info
            });
        }


        if (info.profession == 0)
        {
            Debug.Log("Spawning Knight");
        }

        if (info.profession == 1)
        {
            Debug.Log("Spawning Wizard");
        }

        if (info.profession == 2)
        {
            Debug.Log("Spawning Priest");
        }

        if (info.profession == 3)
        {
            Debug.Log("Spawning Ranger");
        }

        StartCoroutine(SpawnPlayer(info, connection));
    }
    IEnumerator SpawnPlayer(CharacterInfo info, NetworkConnection connection)
    {
        yield return new WaitForSeconds(1f);
        GameObject go = Instantiate(_playerPrefab, new Vector3(3.5f, 0, 2.5f), Quaternion.identity);
        _Player _p = go.GetComponent<_Player>();
        _p.Init(info.id, connection, info);
        List<InventoryItem> inv = database.LoadInventory(info.name);
        _p.SetInventory(inv);
        if (inv.Count == 0)
        {
            _p.AddItem(ItemDatabase.getInstance.getItem(0), 1);
            _p.AddItem(ItemDatabase.getInstance.getItem(1), 1);
        }
        NetworkServer.AddPlayerForConnection(connection, go);
        Debug.Log("Spawning player with id: " + _p.info.id + " position: " + go.transform.position + " name: " + go.name + "profession" + _p.info.profession);



        serverPlayers.Add(_p.info.id, _p);

        foreach (var p in serverPlayers.Values)
        {
            SpawnPacket packet = new SpawnPacket();
            packet.pos = _p.position;
            //packet.rot = _p.rotation;
            packet.id = info.id;
            packet.name = info.name;
            packet.profession = info.profession;
         
            if (p.id == info.id)
                NetworkServer.SendToAll(packet);
            else
                connection.Send(packet);
        }

        InventoryPacket invPacket = new InventoryPacket();
        invPacket.inventory = inv.ToArray();
        connection.Send(invPacket);

        foreach (var item in ItemDatabase.getInstance.droppedItems)
        {
            DroppedItemPacket p = new DroppedItemPacket();
            p.item = item;
            connection.Send(p);
        }

        for (int i = 0; i < AISpawner.spawnedAIs.Count; i++)
            SpawnAI(AISpawner.spawnedAIs[i].id, AISpawner.spawnedAIs[i].data.aiID, AISpawner.spawnedAIs[i].transform.position, AISpawner.spawnedAIs[i].transform.rotation, connection, false);
    }



    public override void OnClientDisconnect(NetworkConnection conn) // not working? 
    {
        Debug.Log("In Client Disconnect");
        foreach (var p in serverPlayers)
        {
            if (p.Value.con == conn)
            {
                serverPlayers.Remove(p.Key);
                //clientPlayers.Remove(p.Key);
                NetworkServer.Destroy(p.Value.gameObject);
                Debug.Log(p.Value.gameObject.name + ": Key:" + p.Key + ": in Client DISCONNECTED");

                return;
            }
        }
    }


    void OnSelectCharacterResponse(NetworkConnection connection, SelectCharacterResponsePacket packet)
    {
        if (packet.response == SelectCharacterResponse.Succssful)
            SceneManager.LoadScene(1);
    }


    void OnCharacterPacket(NetworkConnection connection, CharactersPacket packet)
    {
        CharacterSelection.getInstance.GetCharacters(packet.characters);
    }




    void OnPlayerSpawn(NetworkConnection connection, SpawnPacket packet)
    {
        if (NetworkServer.active) 
            return;

        if (clientPlayers.ContainsKey(packet.id))
            return;

        Debug.Log("Got spawn packet for player with id: " + packet.id);
        GameObject go = Instantiate(_playerPrefab, packet.pos, Quaternion.identity);
        _Player p = go.GetComponent<_Player>();

      

        p.Init(packet.id, connection, new CharacterInfo() { id = packet.id, name = packet.name });
        clientPlayers.Add(packet.id, p);
    }


    void OnSpawnDroppedItem(NetworkConnection connection, DroppedItemPacket packet)
    {
        _Player.local.DropItem(packet.item.item, packet.item.pos, Quaternion.Euler(packet.item.rot), packet.item.id);
    }
    void OnInventoryUpdate(NetworkConnection connection, InventoryPacket packet)
    {
        List<InventoryItem> inv = new List<InventoryItem>();
        inv.AddRange(packet.inventory);
        _Player.local.SetInventory(inv);
    }

    public void SpawnAI(int id, int aiId, Vector3 pos, Quaternion rot, NetworkConnection con, bool toAll)
    {
        SpawnAIPacket packet = new SpawnAIPacket();
        packet.id = id;
        packet.aiId = aiId;
        packet.pos = pos;
        packet.rot = rot;

        if (toAll)
            NetworkServer.SendToAll(packet);
        else
            con.Send(packet);
    }
    public void DespawnAI(int id, NetworkConnection con, bool toAll)
    {
        DespawnAIPacket packet = new DespawnAIPacket();
        packet.id = id;

        if (toAll)
            NetworkServer.SendToAll(packet);
        else
            con.Send(packet);
    }
    void OnSpawnAI(NetworkConnection connection, SpawnAIPacket packet)
    {
        ClientAISpawner.getInstance.Spawn(packet.id, packet.aiId, packet.pos, packet.rot);
    }
    void OnDespawnAI(NetworkConnection connection, DespawnAIPacket packet)
    {
        ClientAISpawner.getInstance.Despawn(packet.id);
    }
}

public class Account
{
    public NetworkConnection connection;
    public string username;
    public string password;
}
public class Player
{
    public Account account;
    public CharacterInfo info;
}