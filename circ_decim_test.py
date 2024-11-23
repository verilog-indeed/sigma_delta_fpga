import array
# somewhat plausible software model for the circular decimator
class circular_decimator:
    def __init__(self, size: int, dec_ratio: int):
        print("henlo baby")
        self.buffer = array.array('i', [0] * size)
        self.maxsize = size
        self.dec_ratio = dec_ratio
        self.rd_ptr = 0
        self.wr_ptr = 0
        self.base_ptr = 0
        self.count = 0
    
    def enqueue(self, item):
        if (self.count < self.maxsize):
            self.buffer[self.wr_ptr] = item
            self.wr_ptr = (self.wr_ptr + 1) % self.maxsize
            self.count = self.count + 1
        else:
            print("oh no couldnt insert item", item)
        
    def dequeue(self):
        if (self.count > 0):
            item = self.buffer[self.rd_ptr]
            self.rd_ptr = (self.rd_ptr + 1) % self.maxsize
            self.count = self.count - 1
            return item
        else:
            print("oh no theres nothing to read!")
            return None

def main():
    print("awooga")
    buff = circular_decimator(3, 1)
    for i in range(5):
        print(i)
        buff.enqueue(i)
    for i in range(5):
        result = buff.dequeue()
        print(result)

    for i in range(5, 10):
        print(i)
        buff.enqueue(i)
    for i in range(5, 10):
        result = buff.dequeue()
        print(result)
    
if __name__ == "__main__":
    main()