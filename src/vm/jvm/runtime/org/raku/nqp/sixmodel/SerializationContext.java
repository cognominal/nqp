package org.raku.nqp.sixmodel;

import java.util.ArrayList;
import java.util.HashMap;

import it.unimi.dsi.fastutil.objects.Object2IntOpenHashMap;
import it.unimi.dsi.fastutil.ints.IntArrayList;

import org.raku.nqp.runtime.CodeRef;

/**
 * A serialization context holds a list of objects and code references that live
 * within a serialization boundary.
 */
public class SerializationContext {
    /* The handle of this SC. */
    public String handle;

    /* Description (probably the file name) if any. */
    public String description;

    /* The root set of objects that live in this SC. */
    private ArrayList<SixModelObject> root_objects;

    /* The root set of STables that live in this SC. */
    private ArrayList<STable> root_stables;

    /* The root set of code refs that live in this SC. */
    private ArrayList<CodeRef> root_codes;

    /* Repossession info. The following lists have matching indexes, each
     * representing the integer of an object in our root set along with the SC
     * that the object was originally from. */
    public IntArrayList rep_indexes;
    public ArrayList<SerializationContext> rep_scs;

    /* Some things we deserialize are not directly in an SC, root set, but
     * rather are owned by others. This is mostly thanks to Parrot legacy,
     * where not everything was a 6model object. This maps such owned
     * objects to their owner. It is used to determine what object should
     * be repossessed in the case a write barrier is hit. */
    public HashMap<SixModelObject, SixModelObject> owned_objects;

    public SerializationContext(String handle) {
        this.handle = handle;
        this.root_objects = new ArrayList<>();
        this.root_stables = new ArrayList<>();
        this.root_codes = new ArrayList<>();
        this.rep_indexes = new IntArrayList();
        this.rep_scs = new ArrayList<>();
        this.owned_objects = new HashMap<>();
    }

    /* Takes an object and adds it to this SC's root set, and installs a
     * reposession entry. */
    public void repossessObject(SerializationContext origSC, SixModelObject obj) {
        /* Check the object really lives in the SC root set. */
        if (obj.sc.root_objects.indexOf(obj) < 0)
            throw new RuntimeException("Attempt to repossess object not in this context");

        /* Add to root set. */
        int newSlot = root_objects.size();
        addObject(obj);

        /* Add repossession entry. */
        rep_indexes.add(newSlot << 1);
        rep_scs.add(origSC);
    }

    /* Takes an STable and adds it to this SC's root set, and installs a
     * reposession entry. */
    public void repossessSTable(SerializationContext origSC, STable st) {
        /* Add to root set. */
        int newSlot = root_stables.size();
        addSTable(st);

        /* Add repossession entry. */
        rep_indexes.add((newSlot << 1) | 1);
        rep_scs.add(origSC);
    }

    private Object2IntOpenHashMap<SixModelObject> objectIndexCache = new Object2IntOpenHashMap<SixModelObject>();
    public void addObject(SixModelObject obj) {
        int newIndex = root_objects.size();
        root_objects.add(obj);
        objectIndexCache.put(obj, newIndex);
    }
    public void addObject(SixModelObject obj, int index) {
        if (index == root_objects.size()) {
            root_objects.add(obj);
        } else {
            root_objects.set(index,  obj);
        }
        objectIndexCache.put(obj, index);
    }
    public int getObjectIndex(SixModelObject obj) {
        return objectIndexCache.getInt(obj);
    }
    public SixModelObject getObject(int index) {
        return root_objects.get(index);
    }
    public int objectCount() {
        return root_objects.size();
    }
    public void initObjectList(int entries) {
        root_objects.ensureCapacity(entries);
        for (int i = 0; i < entries; i++)
            root_objects.add(null);
    }

    private Object2IntOpenHashMap<STable> stableIndexCache = new Object2IntOpenHashMap<STable>();
    public void addSTable(STable stable) {
        int newIndex = root_stables.size();
        root_stables.add(stable);
        stableIndexCache.put(stable, newIndex);
    }
    public void setSTable(int index, STable stable) {
        root_stables.set(index, stable);
        stableIndexCache.put(stable, index);
    }
    public int getSTableIndex(STable stable) {
        return stableIndexCache.get(stable);
    }
    public STable getSTable(int index) {
        return root_stables.get(index);
    }
    public int stableCount() {
        return root_stables.size();
    }
    public void initSTableList(int entries) {
        root_stables.ensureCapacity(entries);
        for (int i = 0; i < entries; i++)
            root_stables.add(null);
    }

    private Object2IntOpenHashMap<CodeRef> codeIndexCache = new Object2IntOpenHashMap<CodeRef>();
    public void addCodeRef(CodeRef coderef) {
        int newIndex = root_codes.size();
        root_codes.add(coderef);
        codeIndexCache.put(coderef, newIndex);
    }
    public void addCodeRef(CodeRef obj, int index) {
        if (index == root_codes.size()) {
            root_codes.add(obj);
        } else {
            root_codes.set(index,  obj);
        }
        codeIndexCache.put(obj, index);
    }
    public int getCodeIndex(SixModelObject coderef) {
        return codeIndexCache.get(coderef);
    }
    public CodeRef getCodeRef(int index) {
        return root_codes.get(index);
    }
    public int coderefCount() {
        return root_codes.size();
    }

    public void disclaimObjects() {
        for (SixModelObject obj : this.root_objects) {
            obj.sc = null;
        }
        this.root_objects = new ArrayList<>();
    }
    public void disclaimSTables() {
        for (STable stable : this.root_stables) {
            stable.sc = null;
        }
        this.root_stables = new ArrayList<>();
    }
    public void disclaimCodes() {
        for (CodeRef obj : this.root_codes) {
            obj.sc = null;
        }
        this.root_codes = new ArrayList<>();
    }
}
