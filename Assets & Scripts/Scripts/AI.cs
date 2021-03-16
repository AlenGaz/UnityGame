using Mirror;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AI : NetworkBehaviour
{
    [System.Serializable]
    public class AttackAnimation
    {
        public int id;
        public float animationTime;
        public float damageTime;
    }

    [SerializeField] BoxCollider col;
    [SerializeField] GridObject gridObject;
    [SerializeField] GridMovement gridMovement;
    [SerializeField] Animator anim;
    [SerializeField] int minAttackAnimation;
    [SerializeField] int maxAttackAnimation;
    [SerializeField] List<AttackAnimation> attackAnimations = new List<AttackAnimation>();
    [SerializeField] GridObject SdPrefab;

    //-------Movement variables--------------------------------------------------------------------------------------------
    //---------------------------------------------------------------------------------------------------------------------
    //diagonal direction vectors
    Vector2 dirvectorQ = new Vector2(-1, 1);
    Vector2 dirvectorE = new Vector2(1, 1);
    Vector2 dirvectorZ = new Vector2(-1, -1);
    Vector2 dirvectorC = new Vector2(1, -1);

    //updown direction vectors 
    Vector2 dirvectorA = new Vector2Int(-1, 0); // left
    Vector2 dirvectorW = new Vector2Int(0, 1);  // top
    Vector2 dirvectorD = new Vector2Int(1, 0);  // right
    Vector2 dirvectorS = new Vector2Int(0, -1); // bottom

    [HideInInspector] public int id;
    [HideInInspector] public AIData data;
    [HideInInspector] public AISpawner spawner;
    [HideInInspector] [SyncVar] public float currentHealth;
    [HideInInspector] [SyncVar] public float currentMana;

    public _Player target;
    float distanceTravelled;
    Vector3 previousPosition;
    Vector3 spawnPosition;
    CharacterPathfinder _characterPathfinder;


    int currentAttackAnimation = -1;

    public bool wonderingAround { get { return target == null; } }
    GridTile targetTile;
    bool movingTo = false;

    bool isDead { get { return currentHealth <= 0; } }

    (_Player, float) lastDamageDealer = default;

    public void Init(int id, AIData data, AISpawner spawner)
    {
        this.id = id;
        this.data = data;
        this.spawner = spawner;

        currentHealth = data.MaxHealth;
        currentMana = data.MaxMana;
        previousPosition = transform.position;
        spawnPosition = transform.position;

        Vector3 colliderSize = new Vector3(data.aggroRange, data.aggroRange, data.aggroRange);
        col.size = colliderSize;

        if (anim != null)
            anim.SetBool("dead", false);

        InitRegen();
    }

    public void Start()
    {
        _characterPathfinder = GetComponent<CharacterPathfinder>();
    }

    [Server]
    void InitRegen()
    {
        InvokeRepeating("Regen", 1f, 1f);
    }
    void Regen()
    {
        currentHealth += data.HealthRegen;
        currentHealth = Mathf.Clamp(currentHealth, 0, data.MaxHealth);

        currentMana += data.ManaRegen;
        currentMana = Mathf.Clamp(currentMana, 0, data.MaxMana);
    }

    [Server]
    public void TakeDamage(float value, _Player attacker)
    {
        if (lastDamageDealer.Item1 != null)
        {
            if (lastDamageDealer.Item1 != attacker)
            {
                if (lastDamageDealer.Item2 > value)
                {
                    SetTarget(attacker);
                    lastDamageDealer = (attacker, value);
                }
            }
            else
                lastDamageDealer.Item2 += value;
        }
        currentHealth -= value;
        currentHealth = Mathf.Clamp(currentHealth, 0, data.maxChaseDistance);
        if (currentHealth <= 0)
            DoDie(attacker);
    }
    [Server]
    void DoDie(_Player killer)
    {
        anim.SetBool("dead", true);

        if (killer != null)
        {
            //add xp
            //add items or spawn to ground
        }

        AISpawner.OnAIDestroy(id, spawner);
        Destroy(gameObject);
    }

    void LateUpdate()
    {
        if (isDead)
            return;


        if (anim != null)
        {
            float velocity = (transform.position - previousPosition).magnitude / Time.deltaTime;
            anim.SetFloat("Speed", velocity);
        }

        /* 
         if (target != null) {
             if (Mathf.Abs(Vector3.Distance(transform.position, target.transform.position)) < 2)
             {
                 
                 return;
             }
         }
         else
         {
             wonderingAround should happen if target = null
         }
         */

        if (Mathf.Abs(Vector3.Distance(target.transform.position, gameObject.transform.position)) > 15f)
        {
         
            Debug.Log("AI returning cause player is too far away");
            SetTarget(null);
        }

        if (distanceTravelled >= data.maxChaseDistance)
        {
            // to return to spawnpoint
            //SetTarget(null);
            movingTo = true;
            targetTile = GridManager.Instance.GetGridTileAtPosition(Vector2Int.FloorToInt(new Vector2(spawnPosition.x, spawnPosition.y)));
            Debug.Log("SHOULD GO TO SPAWN POSITION");

           //MoveTo(targetTile.gameObject);
        }

        if (Mathf.Abs(Vector3.Distance(target.transform.position, gameObject.transform.position)) <= 0f)
        {
            Debug.Log("Close enough to attack");
            return;
        }
        else
        {
            Debug.Log("Chasing cause within chasedistance");
            StartCoroutine(chase());
        }




        //Attack();

        if (wonderingAround)
        {
            if (targetTile != null || movingTo)
            {
                int xOffset = Random.Range(1, 5);
                int yOffset = Random.Range(1, 5);
                Vector2Int pos = gridObject.m_GridPosition;
                pos.x += xOffset;
                pos.y += yOffset;

                targetTile = GridManager.Instance.GetGridTileAtPosition(pos);
                if (targetTile != null)
                {
                    MoveTo(targetTile.gameObject);
                    movingTo = true;
                }
            }

            if (GridManager.Instance.GetGridTileAtPosition(gridObject.m_GridPosition) == targetTile)
            {
                movingTo = false;
                targetTile = null;
            }
        }

        distanceTravelled = Vector3.Distance(transform.position, previousPosition);
        previousPosition = transform.position;
    }



    private void OnTriggerEnter(Collider other)
    {
        if (target == null && !data.AutoAggro)
            return;

        if (other.CompareTag("Player"))
        {

            _Player player = other.GetComponentInParent<_Player>();
            //if (player == null)
                //return;

            //MoveTo(other.transform.parent.gameObject);
            //Debug.Log("distance between target and AI:" + Mathf.Abs(Vector3.Distance(transform.position, player.transform.position)));
            
            SetTarget(player);
            //MoveTo(target.gameObject);
            Debug.Log(target.name + "<-targetname");
        }
        
    }

    private void OnTriggerExit(Collider other)
    {
        // to return to spawnpoint
        //SetTarget(this.gameObject);
        movingTo = true;
        targetTile = GridManager.Instance.GetGridTileAtPosition(Vector2Int.FloorToInt(new Vector2(spawnPosition.x, spawnPosition.y)));
        Debug.Log("onTriggerExit should move back to spawn");
        MoveTo(targetTile.gameObject);
       
    }


        void MoveTo(GameObject targetGameObj)
    {
        GridTile tile;
       
        Vector2Int _neighbourPos;
        if(gameObject.GetComponent<GridMovement>()!= null)
        {
             tile = GridManager.Instance.GetGridTileAtPosition(targetGameObj.GetComponent<GridObject>().m_GridPosition);
             //tile = GridManager.Instance.GetNeighborPositions().[randomIndex] where random index is Random.rand(0,7)
       

             
              _characterPathfinder.SetNewDestination(tile);
        }

        if(gameObject.GetComponent<GridTile>() != null)
        {
            tile = GridManager.Instance.GetGridTileAtPosition(targetGameObj.GetComponent<GridTile>().m_GridPosition);
            Debug.Log("AI should wander towards: " + tile.m_GridPosition);
        }
    }


    void SetTarget(_Player target)
    {
        this.target = target;
        Debug.Log("Set Target: " + target.name);
        distanceTravelled = 0f;
    }

    IEnumerator chase()
    {
        if (target == null)
            yield break;

      

        if (Mathf.Abs(Vector3.Distance(target.transform.position, gameObject.transform.position)) > 2f)
        {
            yield return new WaitForSeconds(0.5f);
            MoveTo(target.gameObject);
            
            Debug.Log(" in chase() cause position not close yet" + Mathf.Abs(Vector3.Distance(target.transform.position, gameObject.transform.position)));
            
        }
        
    }

        void Attack()
    {
        if (target == null)
            return;

        if (data.canCastSpell)
        {
            float value = Random.value;
            int index = Random.Range(0, data.spells.Count - 1);
            if (data.spells[index].spellChance < value && data.spells[index].spell.manaNeeded >= currentMana)
            {
                CastSpell(data.spells[index].spell);
                return;
            }
        }

        currentAttackAnimation++;
        if (currentAttackAnimation > maxAttackAnimation)
            currentAttackAnimation = 0;

        StartCoroutine(attack());
    }
    IEnumerator attack()
    {
        Debug.Log("In AI coroutine attack");
        (float, float) time = getAttackTime(currentAttackAnimation);
        if (time.Item1 == -1 || time.Item2 == -1)
            yield break;

        if (anim != null)
        {
            anim.SetFloat("attackId", currentAttackAnimation);
            anim.SetBool("attack", true);
        }
        yield return new WaitForSeconds(time.Item2);
        target.TakeDamage(data.Damage);
        yield return new WaitForSeconds(time.Item1 - time.Item2);
        if (anim != null)
            anim.SetBool("attack", false);
    }
    void CastSpell(Spell spell)
    {
        currentMana -= spell.manaNeeded;
        currentMana = Mathf.Clamp(currentMana, 0, data.MaxMana);

        StartCoroutine(createSpellTiles(spell));
    }
    IEnumerator createSpellTiles(Spell spell)
    {
        GridTile center = gridObject.m_CurrentGridTile;
        List<GridTile> spellTiles = new List<GridTile>() { center };
        spellTiles.AddRange(GetSpellTiles(spell, center));

        for (int i = 0; i < spellTiles.Count; i++)
        {
            if (spellTiles[i] == null)
                continue; 
            
            RpcSpawnSpellTile(new Vector3(spellTiles[i].m_GridPosition.x, spellTiles[i].m_GridPosition.y, 0), spell.ID);
            Vector2Int p = spellTiles[i].m_GridPosition;
            if (p != gridObject.m_CurrentGridTile.m_GridPosition)
            {
                GridObject o = GridManager.Instance.InstantiateGridAbility(spell.prefab == null ? SdPrefab : spell.prefab, p);
                Destroy(o.gameObject, spell.prefabDestroyTime);
            }
            yield return null;
            GridObject obj = GridManager.Instance.GetGridObjectAtPosition(spellTiles[i].m_GridPosition);

            if (obj != null)
            {
                float damageRng = 0f;
                if (obj.CompareTag("Character"))
                {
                    _Player player = obj.transform.root.GetComponent<_Player>();
                    if (player == null)
                        continue;

                    if (player.id == id && !spell.dealDamage && spell.type != SpellType.Support)
                        continue;

                    if (player.id != id && spell.dealDamage || spell.type == SpellType.Attack || player.gameObject != this.gameObject)
                    {
                        damageRng = (Random.Range(0, spell.rngRange)) + spell.value;
                        damageRng = Mathf.Floor(damageRng);

                        player.TakeDamage(damageRng);
                        Debug.Log("Taking Damage:" + damageRng + "player:" + player.name);
                    }
                }
            }
        }
    }
    [ClientRpc]
    void RpcSpawnSpellTile(Vector3 pos, int spellId)
    {
        if (isServer)
            return;

        Spell spell = SpellDatabase.getInstance.getSpell(spellId);
        Vector2Int p = new Vector2Int((int)pos.x, (int)pos.y);
        if (p != GetComponent<GridObject>().m_CurrentGridTile.m_GridPosition)
        {
            GridObject o = GridManager.Instance.InstantiateGridAbility(spell.prefab == null ? SdPrefab : spell.prefab, p);
            Destroy(o.gameObject, spell.prefabDestroyTime);
        }
    }
    List<GridTile> GetSpellTiles(Spell spell, GridTile middleTile)
    {
        List<GridTile> tiles = new List<GridTile>();
        if (spell == null)
            return tiles;

        GridTile currentTile = middleTile;

        for (int i = 0; i < spell.aoe.Length; i++)
        {
            if (spell.aoe[i] != SpellDirection.Middle)
                GetSpellTile(ref currentTile, spell.aoe[i]);
            else
            {
                currentTile = middleTile;
                continue;
            }

            if (currentTile == null || tiles.Contains(currentTile))
                continue;

            tiles.Add(currentTile);
        }

        return tiles;
    }
    void GetSpellTile(ref GridTile currentTile, SpellDirection direction)
    {
        if (currentTile == null || direction == SpellDirection.Middle)
            return;

        Vector2Int v = currentTile.m_GridPosition;
        Vector2Int facing = gridObject.m_FacingDirection;

        if (direction == SpellDirection.Top)
            v.y += 1;
        else if (direction == SpellDirection.Down)
            v.y -= 1;
        else if (direction == SpellDirection.Left)
            v.x -= 1;
        else if (direction == SpellDirection.Right)
            v.x += 1;
        else if (direction == SpellDirection.TopLeft)
        {
            v.x -= 1;
            v.y += 1;
        }
        else if (direction == SpellDirection.TopRight)
        {
            v.x += 1;
            v.y += 1;
        }
        else if (direction == SpellDirection.DownLeft)
        {
            v.x -= 1;
            v.y -= 1;
        }
        else if (direction == SpellDirection.DownRight)
        {
            v.x += 1;
            v.y -= 1;
        }

        else if (direction == SpellDirection.Facing)
        {
            //Vector2Int facing = GetComponent<GridObject>().m_FacingDirection;
            //Debug.Log("pLayer casting and facgin" + gameObject.name + "//" + facing);

            if (facing == dirvectorW)
            {
                v.y += 1;
            }
            if (facing == dirvectorA)
            {
                v.x -= 1;
            }
            if (facing == dirvectorS)
            {
                v.y -= 1;
            }
            if (facing == dirvectorD)
            {
                v.x += 1;
            }
        }
        else if (direction == SpellDirection.FacingLeft)
        {
            if (facing == dirvectorW)
            {
                v.x -= 1;
            }

            if (facing == dirvectorS)
            {

                v.x -= 1;
            }

            if (facing == dirvectorA)
            {

                v.y -= 1;
            }

            if (facing == dirvectorD)
            {

                v.y += 1;
            }


        }


        else if (direction == SpellDirection.FacingRight)
        {
            if (facing == dirvectorW)
            {
                v.x += 1;
            }

            if (facing == dirvectorS)
            {
                v.x += 1;
            }

            if (facing == dirvectorA)
            {
                v.y += 1;
            }

            if (facing == dirvectorD)
            {

                v.y -= 1;
            }
        }
        currentTile = GridManager.Instance.GetGridTileAtPosition(v);
    }

    (float, float) getAttackTime(int animId)
    {
        for (int i = 0; i < attackAnimations.Count; i++)
        {
            if (attackAnimations[i].id == animId)
                return (attackAnimations[i].animationTime, attackAnimations[i].damageTime);
        }

        return (-1, -1);
    }
}
