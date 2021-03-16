using Mirror;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AISpawner : MonoBehaviour
{
    [SerializeField] AIData[] ais;

    [SerializeField] int[] toBeSpawned;
    [SerializeField] float delayBetweenSpawns;
    [SerializeField] int maxCount;
    public bool respawn;
    [SerializeField] BoxCollider spawnLocation;

    public static List<AI> spawnedAIs = new List<AI>();

    void Start()
    {
        if (!NetworkServer.active)
        {
            Destroy(gameObject);
            return;
        }

        if (NetworkServer.active)
            Spawn();
    }

    public void Spawn()
    {
        StartCoroutine(spawn());
    }
    IEnumerator spawn()
    {
        for (int i = 0; i < maxCount; i++)
        {
            SpawnRandom();
            yield return new WaitForSeconds(delayBetweenSpawns);
        }
    }
    void SpawnRandom()
    {
        AIData data = getAIData(toBeSpawned[Random.Range(0, toBeSpawned.Length - 1)]);
        Debug.Log("Spawning ai, data found: " + (data != null));
        if (data == null)
            return;

        Vector3 pos = getSpawnPosition();
        GridTile tile = GridManager.Instance.GetGridTileAtPosition(Vector2Int.CeilToInt(new Vector2(pos.x, pos.z)));
        GridObject obj = GridManager.Instance.InstantiateGridObject(data.prefab.GetComponent<GridObject>(), (Vector2Int.CeilToInt(new Vector2(pos.x, pos.z))));
        //GameObject obj = Instantiate(data.prefab, getSpawnPosition(), Quaternion.identity);
        obj.name = "SpawnedAI";
        AI ai = obj.GetComponent<AI>();
        ai.Init(generateId(), data, this);
        spawnedAIs.Add(ai);
        NetworkingManager.getInstance.SpawnAI(ai.id, data.aiID, ai.transform.position, ai.transform.rotation, null, true);
    }

    public static void OnAIDestroy(int id, AISpawner spawner)
    {
        for (int i = 0; i < spawnedAIs.Count; i++)
        {
            if (spawnedAIs[i].id == id)
            {
                spawnedAIs.RemoveAt(i);
                NetworkingManager.getInstance.DespawnAI(id, null, true);
                if (spawner.respawn)
                    spawner.SpawnRandom();

                return;
            }
        }
    }

    AIData getAIData(int id)
    {
        for (int i = 0; i < ais.Length; i++)
        {
            if (ais[i].aiID == id)
                return ais[i];
        }

        return null;
    }

    Vector3 getSpawnPosition()
    {
        float x = Random.Range(spawnLocation.bounds.min.x, spawnLocation.bounds.max.x);
        float y = Random.Range(spawnLocation.bounds.min.y, spawnLocation.bounds.max.y);
        float z = Random.Range(spawnLocation.bounds.min.z, spawnLocation.bounds.max.z);

        return new Vector3(x, y, z);
    }

    static bool idExists(int id)
    {
        for (int i = 0; i < spawnedAIs.Count; i++)
        {
            if (spawnedAIs[i].id == id)
                return true;
        }

        return false;
    }
    static int generateId()
    {
        int id = Random.Range(0, int.MaxValue);
        while (idExists(id))
            id = Random.Range(0, int.MaxValue);
        return id;
    }

    static AI getAI(int id)
    {
        for (int i = 0; i < spawnedAIs.Count; i++)
        {
            if (spawnedAIs[i].id == id)
                return spawnedAIs[i];
        }

        return null;
    }
}