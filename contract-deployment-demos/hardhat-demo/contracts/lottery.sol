// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Lottery {
    // 定义彩票购买者的结构
    struct Ticket {
        address buyer;
        uint[] numbers; // 前区号码
        uint[] extraNumbers; // 后区号码
        uint amount; // 购买金额
    }
    
    // 结构体，用于存储中奖信息
    struct Winner {
        address winnerAddress;
        uint amount;
    }
    
    // 存储彩票购买记录
    Ticket[] public tickets;
    
    // 彩票期数
    uint public round;
    
    // 彩票购买截止区块高度
    uint public deadlineBlock;
    
    // 定义事件，用于通知前端
    event TicketPurchased(address indexed buyer, uint[] numbers, uint[] extraNumbers, uint amount);
    event LotteryEnded(uint round, uint[] winningNumbers, uint[] winningExtraNumbers);
    
    // 构造函数，初始化彩票期数和购买截止区块高度
    constructor(uint _deadlineBlocks) {
        round = 1;
        deadlineBlock = block.number + _deadlineBlocks;
    }
    
    // 购买彩票
    function purchaseTicket(uint[] memory _numbers, uint[] memory _extraNumbers) public payable {
        // 检查购买时间是否在截止时间之前
        require(block.number < deadlineBlock, "Ticket purchase period has ended.");
        // 检查付款金额是否足够
        require(msg.value == 200000000 gwei, "Contribution must be exactly 0.2 ether");
        // 检查号码数量是否正确
        require(_numbers.length == 5 && _extraNumbers.length == 2, "Incorrect number of numbers.");
        
        // 将购买记录添加到 tickets 数组中
        Ticket memory newTicket = Ticket(msg.sender, _numbers, _extraNumbers, msg.value);
        tickets.push(newTicket);
        
        // 触发购买事件
        emit TicketPurchased(msg.sender, _numbers, _extraNumbers, msg.value);
    }
    
    // 开奖
    function endLottery() public {
        // 检查是否到达截止时间
        require(blockhash(deadlineBlock) != 0,"Invalid block number.");
        require(block.number >= deadlineBlock, "Lottery has not ended yet.");
        // 生成中奖号码
        (uint[] memory winningNumbers, uint[] memory winningExtraNumbers) = generateWinningNumbers();
        
        // 分配奖金
        distributePrizes(winningNumbers, winningExtraNumbers);
        
        // 触发开奖事件
        emit LotteryEnded(round, winningNumbers, winningExtraNumbers);
        
        // 增加彩票期数
        round++;
        // 更新购买截止区块高度
        deadlineBlock = block.number + deadlineBlock;
    }
    
    // 生成中奖号码
    function generateWinningNumbers(uint blockNumber) public view returns (uint[] memory, uint[] memory) {
        // 获取指定区块的哈希值
        bytes32 blockHash = blockhash(blockNumber);
        // 确保区块哈希值不为空
        require(blockHash != 0, "Invalid block number.");
        
        // 将哈希值转换为uint类型，并截取前区号码和后区号码
        uint[] memory winningNumbers = new uint[](5);
        uint[] memory winningExtraNumbers = new uint[](2);
        for (uint i = 0; i < 5; i++) {
            winningNumbers[i] = uint8(blockHash[i]) % 35 + 1;
        }
        for (uint i = 5; i < 7; i++) {
            winningExtraNumbers[i - 5] = uint8(blockHash[i]) % 12 + 1;
        }
        
        return (winningNumbers, winningExtraNumbers);
    }
    // 奖金分配
    function distributePrizes(uint[] memory winningNumbers, uint[] memory winningExtraNumbers) private {
        Winner[] memory winners;
        
        // 遍历所有购买的彩票
        for (uint i = 0; i < tickets.length; i++) {
            uint matchCount = 0;
            uint extraMatchCount = 0;
            Ticket memory ticket = tickets[i];
            
            // 检查前区号码中有多少匹配
            for (uint j = 0; j < 5; j++) {
                for (uint k = 0; k < 5; k++) {
                    if (ticket.numbers[j] == winningNumbers[k]) {
                        matchCount++;
                        break;
                    }
                }
            }
            
            // 检查后区号码中有多少匹配
            for (uint j = 0; j < 2; j++) {
                for (uint k = 0; k < 2; k++) {
                    if (ticket.extraNumbers[j] == winningExtraNumbers[k]) {
                        extraMatchCount++;
                        break;
                    }
                }
            }
            
            // 根据匹配数量确定奖级，并计算奖金
            uint prize = calculatePrize(matchCount, extraMatchCount);
            
            // 如果中奖，将中奖者信息存储到 winners 数组中
            if (prize > 0) {
                winners.push(Winner(ticket.buyer, prize));
            }
        }
        
        // 发送奖金给中奖者
        for (uint i = 0; i < winners.length; i++) {
            payable(winners[i].winnerAddress).transfer(winners[i].amount);
        }
    }
    
    // 计算奖金
    function calculatePrize(uint matchCount, uint extraMatchCount) private pure returns (uint) {
        // 根据中奖条件确定奖金
        if (matchCount == 5 && extraMatchCount == 1) {
            return 5000000; // 一等奖
        } else if (matchCount == 5) {
            return 10000; // 三等奖
        } else if (matchCount == 4 && extraMatchCount == 2) {
            return 3000; // 四等奖
        } else if ((matchCount == 4 && extraMatchCount == 1) || (matchCount == 3 && extraMatchCount == 2)) {
            return 300; // 五等奖
        } else if ((matchCount == 3 && extraMatchCount == 1) || (matchCount == 2 && extraMatchCount == 2)) {
            return 200; // 六等奖
        } else if (matchCount == 4) {
            return 100; // 七等奖
        } else if ((matchCount == 3 && extraMatchCount == 1) || (matchCount == 1 && extraMatchCount == 2) || extraMatchCount == 2) {
            return 15; // 八等奖
        } else if ((matchCount == 3) || (matchCount == 1 && extraMatchCount == 2) || (matchCount == 2 && extraMatchCount == 1) || extraMatchCount == 1) {
            return 5; // 九等奖
        } else {
            return 0; // 未中奖
        }
    }
    
    // 获取当前彩票期数
    function getCurrentRound() public view returns (uint) {
        return round;
    }
    
    // 获取购买截止区块高度
    function getDeadlineBlock() public view returns (uint) {
        return deadlineBlock;
    }
}