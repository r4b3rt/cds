package ckgroup

import (
	"errors"
	"fmt"
	"github.com/tal-tech/cds/pkg/ckgroup/dbtesttool/dbtool"
	"testing"
)

func Test_dbGroup_InsertAutoDetail(t *testing.T) {
	dataSet := dbtool.GenerateDataSet(10000)

	c1 := dbGroup{
		ShardNodes: []ShardConn{&fakeInsertShardConn{true}, &fakeInsertShardConn{true}, &fakeInsertShardConn{true}},
		opt:        option{RetryNum: 3},
	}
	errDetail1, err := c1.InsertAutoDetail(``, "pk", dataSet)
	if err != nil {
		t.Fatal(err)
	}
	for i, item := range errDetail1 {
		if i+1 != item.ShardIndex {
			t.Fatal("shard index error")
		}
		fmt.Println(item.ShardIndex)
		fmt.Println(item.Err)
		fmt.Println(len(item.Datas.([]*dbtool.DataInstance)))
	}
	c2 := dbGroup{
		ShardNodes: []ShardConn{&fakeInsertShardConn{false}, &fakeInsertShardConn{false}, &fakeInsertShardConn{false}},
		opt:        option{RetryNum: 3},
	}
	errDetail2, err := c2.InsertAutoDetail(``, "pk", dataSet)
	if err != nil {
		t.Fatal(err)
	}
	if len(errDetail2) != 0 {
		t.Fatal("count not 0")
	}

	c3 := dbGroup{
		ShardNodes: []ShardConn{&fakeInsertShardConn{false}, &fakeInsertShardConn{true}, &fakeInsertShardConn{false}},
		opt:        option{RetryNum: 3},
	}
	errDetail3, err := c3.InsertAutoDetail(``, "pk", dataSet)
	if err != nil {
		t.Fatal(err)
	}
	if errDetail3[0].ShardIndex != 2 {
		t.Fatal("shard index not 2")
	}
	fmt.Println(errDetail3[0].ShardIndex)
	fmt.Println(errDetail3[0].Err)
	fmt.Println(len(errDetail3[0].Datas.([]*dbtool.DataInstance)))
}

type fakeInsertShardConn struct {
	isFail bool
}

func (i *fakeInsertShardConn) GetAllConn() []CKConn {
	panic("implement me")
}

func (i *fakeInsertShardConn) GetReplicaConn() []CKConn {
	panic("implement me")
}

func (i *fakeInsertShardConn) GetShardConn() CKConn {
	panic("implement me")
}

func (i *fakeInsertShardConn) Exec(ignoreErr bool, query string, args ...interface{}) []hostErr {
	panic("implement me")
}

func (i *fakeInsertShardConn) ExecReplica(ignoreErr bool, query string, args ...interface{}) []hostErr {
	panic("implement me")
}

func (i *fakeInsertShardConn) ExecAuto(query string, args ...interface{}) error {
	panic("implement me")
}

func (i *fakeInsertShardConn) InsertAuto(query string, sliceData interface{}) error {
	if i.isFail {
		return errors.New("fake insert error")
	}
	return nil
}

func (i *fakeInsertShardConn) Close() {
	panic("implement me")
}
