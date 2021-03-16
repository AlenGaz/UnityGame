using MySql.Data.MySqlClient;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DatabaseManager : MonoBehaviour
{	......
	............
	..................

    public void Init()
    {
        Connect();
    }
    void OnApplicationQuit()
    {
        closeConnection();
    }

    public LoginResponse Login(string username, string password, ref string chars)
    {
        if (string.IsNullOrEmpty(username) || string.IsNullOrEmpty(password))
            return LoginResponse.AccountNotFound;

        try
        {
            //if (UserIsConnected(username))
            //    return LoginResponse.LoggedIn;

            if (openConnection())
            {
                string query = "SELECT * FROM accounts WHERE username='" + username + "' AND password='" + password + "'";
                MySqlCommand cmd = new MySqlCommand(query, connection);
                MySqlDataReader reader = cmd.ExecuteReader();

                if (reader.Read())
                {
                    chars = reader.GetString(reader.GetOrdinal("characters"));
                    reader.Close();

                    	......
			............
			..................

                }
                else
                {
                    reader.Close();
                    return LoginResponse.AccountNotFound;
                }
            }
        }
        catch (MySqlException ex)
        {
            Debug.LogError("Error on login for user with username: " + username + " with error: " + ex.Message);
            return LoginResponse.InternalError;
        }

        return LoginResponse.Successful;
    }
    public RegistrationResponse Register(string email, string username, string password)
    {
        if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(username) || string.IsNullOrEmpty(password))
            return RegistrationResponse.AccountAlreadyExists;

        try
        {
            if (UserExists(username))
                return RegistrationResponse.AccountAlreadyExists;

            if (UserExists2(email))
                return RegistrationResponse.AccountAlreadyExists;

            if (openConnection())
            {
                string query = "INSERT INTO accounts(email, username, password, isOnline, characters) VALUES('" + email + "', '" + username + "', '" + password + "', '0', '')";
                MySqlCommand cmd = new MySqlCommand(query, connection);
                cmd.ExecuteNonQuery();
            }
        }
        catch (MySqlException ex)
        {
            Debug.LogError("Error on registering a new user with error: " + ex.Message);
            return RegistrationResponse.InternalError;
        }

        return RegistrationResponse.Successful;
    }
    bool UserExists(string username)
    {
        bool res = false;

        try
        {
            if (openConnection())
                    currentTry++;

                    if (currentTry >= maxTries)
                        return CreateCharacterResponse.InternalError;
                }

            //string query = "INSERT INTO characters(id, account, name, maxHealth, maxMana, exp, profession) VALUES('" + id + "', '" + username + "', '" + name + "', '" + 100 + "', '" + 100 + "', '" + 0 + "', '" + 1 + "');";
            string query = "INSERT INTO characters(id, account, name, maxHealth, maxMana, exp, profession) VALUES('" + id + "', '" + username + "', '" + name + "', '" + 100 + "', '" + 100 + "', '" + 0 + "','" + profession + "');";
            Debug.Log("queryDBISIB" + profession);
                MySqlCommand cmd = new MySqlCommand(query, connection);
                cmd.ExecuteNonQuery();

                query = "SELECT * FROM accounts WHERE username='" + username + "';";
                cmd = new MySqlCommand(query, connection);
                MySqlDataReader reader = cmd.ExecuteReader();
                string chars = "";

                if (reader.Read())
                    chars = reader.GetString(reader.GetOrdinal("characters"));

                reader.Close();

                if (!string.IsNullOrEmpty(chars))
                    chars += ";";

                chars += id;

                query = "UPDATE accounts SET characters='" + chars + "' WHERE username='" + username + "';";
                //query = "UPDATE accounts SET characters='" + chars + "' WHERE username='" + username + "','" + profession + "';";
                cmd = new MySqlCommand(query, connection);
                cmd.ExecuteNonQuery();

                return CreateCharacterResponse.Successful;
            }
        

        return CreateCharacterResponse.InternalError;
    }
    public CharacterInfo LoadCharacter(int id)
    {
        if (id < 0)
            return null;

        try
        {
            if (openConnection())
            {
                string query = "SELECT * FROM characters WHERE id='" + id + "';";
                MySqlCommand cmd = new MySqlCommand(query, connection);
                MySqlDataReader reader = cmd.ExecuteReader();
                CharacterInfo info = null;

                if (reader.Read())
                {
                    info = new CharacterInfo();
                    info.id = id;
                    info.name = reader.GetString(reader.GetOrdinal("name"));
                    info.maxHealth = reader.GetFloat(reader.GetOrdinal("maxHealth"));
                    info.maxMana = reader.GetFloat(reader.GetOrdinal("maxMana"));
                    info.exp = reader.GetFloat(reader.GetOrdinal("exp"));
                    info.profession = reader.GetInt32(reader.GetOrdinal("profession"));
                }

                reader.Close();

                return info;
            }
        }
        catch (MySqlException ex) { Debug.LogError(ex.Message); }

        return null;
    }
    public void SaveCharacter(CharacterInfo info)
    {
        try
        {
            if (openConnection())
            {
                string query = "UPDATE characters SET name='" + info.name + "', maxHealth='" + info.maxHealth + "', maxMana='" + info.maxMana + "', exp='" + info.exp + "' WHERE id='" + info.id + "'";

                MySqlCommand cmd = new MySqlCommand(query, connection);
                cmd.ExecuteNonQuery();
            }
        }
        catch (MySqlException ex) { Debug.LogError(ex.Message); }
    }
    bool CharacterExists(int id)
    {
        bool res = false;

        try
        {
            if (openConnection())
            {
                string query = "SELECT * FROM characters WHERE id='" + id + "';";
                MySqlCommand cmd = new MySqlCommand(query, connection);
                MySqlDataReader reader = cmd.ExecuteReader();

                if (reader.Read())
                    res = true;

                reader.Close();
            }
        }
        catch (MySqlException ex) { Debug.LogError(ex.Message); }

        return res;
    }
    bool CharacterExists(string name)
    {
        bool res = false;

        try
        {
            if (openConnection())
            {
                string query = "SELECT * FROM characters WHERE name='" ........
                if (reader.Read())
                    res = true;

                reader.Close();
            }
        }
        catch (MySqlException ex) { Debug.LogError(ex.Message); }

        return res;
    }

    public List<InventoryItem> LoadInventory(string playerName)
    {
        List<InventoryItem> items = new List<InventoryItem>();

        try
        {
            if (openConnection())
            {
                string query = "SELECT * FROM inventory WHERE name='" + playerName + "'";
                MySqlCommand cmd = new MySqlCommand(query, connection);
                MySqlDataReader reader = cmd.ExecuteReader();

                while (reader.Read())
                {
                    InventoryItem item = new InventoryItem();
                    item.Item = reader.GetInt32(reader.GetOrdinal("ItemID"));
                    item.Quantity = reader.GetInt32(reader.GetOrdinal("Quantity"));
                    item.Slot = (ItemSlot)reader.GetInt32(reader.GetOrdinal("Slot"));
                    items.Add(item);
                }

                reader.Close();
            }
        }
        catch (MySqlException ex) { Debug.Log(ex.Message); }

        return items;
    }
 
    public void UpdateInventorySlot(string playerName, int itemID, ItemSlot slot)
    {
        try
        {
            string query = "UPDATE inventory SET Slot='" + (int)slot + "' WHERE name='" + name + "' AND ItemID='" + itemID + "'";
            MySqlCommand cmd = new MySqlCommand(query, connection);
            cmd.ExecuteNonQuery();
        }
        catch (MySqlException ex) { Debug.Log(ex.Message); }
    }

    public void AddItemInInventory(string playerName, int itemID, int quantity)
    {
        try
        {
            if (openConnection())
            {
                string query = "INSERT INTO inventory(name, ItemID, Quantity, Slot) VALUES('" + playerName + "', '" + itemID + "', '" + quantity + "', '0')";

                MySqlCommand cmd = new MySqlCommand(query, connection);
                cmd.ExecuteNonQuery();
            }
        }
        catch (MySqlException ex) { Debug.Log(ex.Message); }
    }

    public List<DroppedItem> LoadDroppedItems()
    {
        List<DroppedItem> items = new List<DroppedItem>();

        try
        {
            if (openConnection())
            {
                string query = "SELECT * FROM droppedItems";

                MySqlCommand cmd = new MySqlCommand(query, connection);
                MySqlDataReader reader = cmd.ExecuteReader();

                while (reader.Read())
                {
                    DroppedItem item = new DroppedItem();
                    item.id = reader.GetInt32(reader.GetOrdinal("ID"));
                    item.item = reader.GetInt32(reader.GetInt32("ItemID"));
                    float x = float.Parse(reader.GetString(reader.GetOrdinal("posX")));
                    float y = float.Parse(reader.GetString(reader.GetOrdinal("posY")));
                    float z = float.Parse(reader.GetString(reader.GetOrdinal("posZ")));
                    float rx = float.Parse(reader.GetString(reader.GetOrdinal("rotX")));
                    float ry = float.Parse(reader.GetString(reader.GetOrdinal("rotY")));
                    float rz = float.Parse(reader.GetString(reader.GetOrdinal("rotZ")));
                    item.pos = new Vector3(x, y, z);
                    item.rot = new Vector3(rx, ry, rz);
                    items.Add(item);
                }

                reader.Close();
            }
        }
        catch (MySqlException ex) { Debug.Log(ex.Message); }

        return items;
    }
    public void DropItem(int id, int itemID, Vector3 pos, Vector3 rot)
    {
        try
        {
            if (openConnection())
            {
               
            }
        }
        catch (MySqlException ex) { Debug.Log(ex.Message); }
    }
    public void PickUpItem(int id)
    {
        try
        {
            if (openConnection())
            {
                
            }
        }
        catch (MySqlException ex) { Debug.Log(ex.Message); }
    }

    MySqlConnection connection;
    void Connect()
    {
        string connectionString = "Server=" + DbServer + ";Database=" + DbName + ";Uid=" + DbUsername + ";Pwd=" + DbPassword + ";SslMode=" + DBSSslMode + ";";
        connection = new MySqlConnection(connectionString);

        int tries = 0;
        int maxTries = 10;

        while (!openConnection())
        {
            tries++;
            if (tries > maxTries)
                return;
        }
    }
    bool openConnection()
    {
        if (connection == null)
            Connect();

        try
        {
            connection.OpenAsync();
            return true;
        }
        catch (MySqlException ex)
        {
            Debug.Log("Error on opening a database connection! " + ex.Message);
            return false;
        }
    }
    bool closeConnection()
    {
        if (connection == null)
        {
            Debug.Log("Trying to close a null database connection!");
            return false;
        }

        try
        {
            connection.Close();
            return true;
        }
        catch (MySqlException ex)
        {
            Debug.Log("Error on closing a database connection: " + ex.Message);
            return false;
        }
    }
}